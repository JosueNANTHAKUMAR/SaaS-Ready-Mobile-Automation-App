FROM ubuntu:18.04 AS mobile

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa openjdk-8-jdk wget \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/developer/app
WORKDIR /home/developer

# Prepare Android directories and system variables
RUN mkdir -p Android/sdk
ENV ANDROID_SDK_ROOT /home/developer/Android/sdk
RUN mkdir -p .android && touch .android/repositories.cfg

# Set up Android SDK
RUN wget -O sdk-tools.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
RUN unzip sdk-tools.zip && rm sdk-tools.zip
RUN mv tools Android/sdk/tools
RUN cd Android/sdk/tools/bin && yes | ./sdkmanager --licenses
RUN cd Android/sdk/tools/bin && ./sdkmanager "build-tools;29.0.2" "patcher;v4" "platform-tools" "platforms;android-29" "sources;android-29"
ENV PATH "$PATH:/home/developer/Android/sdk/platform-tools"

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git
ENV PATH "$PATH:/home/developer/flutter/bin"
RUN flutter upgrade
RUN flutter doctor

# Install Java 11
RUN apt-get update && apt-get install -y openjdk-11-jdk
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

# Copy the rest of the app
COPY ./mobile/ /home/developer/app
WORKDIR /home/developer/app/gamestore
RUN flutter pub get
RUN flutter build apk --release

RUN cp build/app/outputs/apk/release/app-release.apk /home/developer/app/shared/centralize.apk

FROM node:16-alpine AS node

WORKDIR /app

COPY ./app/ .

RUN npm install

RUN npm run build

FROM nginx:alpine

COPY ./app/nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=node /app/dist/centralize /usr/share/nginx/html
COPY --from=mobile /home/developer/app/shared/centralize.apk /usr/share/nginx/html/client.apk

EXPOSE 80