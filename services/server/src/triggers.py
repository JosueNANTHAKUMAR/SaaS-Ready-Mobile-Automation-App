from . import db, scheduler
import smtplib
from email.mime.text import MIMEText
from os import environ
from datetime import datetime, timedelta
import requests
from time import sleep

######################    ACTIONS    ######################
def date_and_time_alert(area, action_idx=0):
    date = area.actions[action_idx].parameters[0].value
    time = area.actions[action_idx].parameters[1].value
    
    date = datetime.strptime(date, "%Y-%m-%d")
    time = datetime.strptime(time, "%H:%M")
    date = datetime.combine(date, time.time())
    
    now = datetime.now()
    date = date - timedelta(hours=2)
    
    if now >= date:
        print("Date and time passed")
        reactions[area.reactions[action_idx].name](area)
###########################################################
def every_day_at(area, action_idx=0):
    time = area.actions[action_idx].parameters[0].value
    
    time = datetime.strptime(time, "%H:%M")
    now = datetime.now()
    time = datetime.combine(now, time.time())
    time = time - timedelta(hours=2)
    
    if now >= time:
        print("Time passed")
        reactions[area.reactions[action_idx].name](area)
###########################################################
def every_month_at(area, action_idx=0):
    day = area.actions[action_idx].parameters[0].value
    time = area.actions[action_idx].parameters[1].value

    day = int(day) if int(day) > 0 else 1
    day = int(day) if int(day) < 32 else 31

    time = datetime.strptime(time, "%H:%M")
    now = datetime.now()
    time = datetime.combine(now, time.time())
    time = time - timedelta(hours=2)

    if now >= time and now.day == day:
        print("Time passed")
        reactions[area.reactions[action_idx].name](area)
###########################################################
def every_year_at(area, action_idx=0):
    day = area.actions[action_idx].parameters[0].value
    month = area.actions[action_idx].parameters[1].value
    time = area.actions[action_idx].parameters[2].value

    day = int(day) if int(day) > 0 else 1
    day = int(day) if int(day) < 32 else 31

    month = int(month) if int(month) > 0 else 1
    month = int(month) if int(month) < 13 else 12

    time = datetime.strptime(time, "%H:%M")
    now = datetime.now()
    time = datetime.combine(now, time.time())
    time = time - timedelta(hours=2)

    if now >= time and now.day == day and now.month == month:
        print("Time passed")
        reactions[area.reactions[action_idx].name](area)
###########################################################
def crypto_crossing_alert(area):
    crypto = area.actions[0].parameters[0].value
    price = area.actions[0].parameters[1].value
    price = float(price)
    response = requests.get(
        url="https://rest.coinapi.io/v1/ohlcv/BINANCE_SPOT_"+ str(crypto).upper() +"_EUR/latest?period_id=1HRS&limit=2",
        headers={
            "Accept": "application/json",
            "X-CoinAPI-Key": environ.get('COINAPI_KEY') or ''
        }
    )
    json = response.json()
    latest_close = json[0].get('price_close')
    previous_close = json[1].get('price_close')
    
    if previous_close < price and latest_close >= price:
        print("Price crossed")
        reactions[area.reactions[0].name](area)
    elif previous_close > price and latest_close <= price:
        print("Price crossed")
        reactions[area.reactions[0].name](area)
###########################################################
def forex_crossing_alert(area):
    first_currency = area.actions[0].parameters[0].value
    second_currency = area.actions[0].parameters[1].value
    price = area.actions[0].parameters[2].value
    price = float(price)
    valueTab = []
    scheduler.remove_job(str(area.id))
    while True:
        sleep(30)
        response = requests.get(
            url='https://api.metalpriceapi.com/v1/latest' +
                '?api_key=' + (str(environ.get('METALPRICE_API_KEY')) or '') +
                '&base=' + str(first_currency).upper() +
                '&currencies=' + str(second_currency).upper()
        )
        rates = response.json().get('rates')
        value = rates.get(str(second_currency).upper())
        valueTab.append(value)
        if len(valueTab) > 1:
            if valueTab[-2] < price and valueTab[-1] >= price:
                print("Price crossed")
                reactions[area.reactions[0].name](area)
                return
            elif valueTab[-2] > price and valueTab[-1] <= price:
                print("Price crossed")
                reactions[area.reactions[0].name](area)
                return
            valueTab.pop(0)
###########################################################
def new_repo_created(area):
    repo_old = []
    scheduler.remove_job(str(area.id))
    for service in area.user.services:
        if service.name == "Github":
            response = requests.get(
                url="https://api.github.com/user/repos",
                headers={
                    "Accept": "application/vnd.github+json",
                    "Authorization": "Bearer " + service.token,
                    "X-GitHub-Api-Version": "2022-11-28"
                }
            )
            print(response.json())
            for repo in response.json():
                repo_old.append(repo.get('name'))
    while True:
        sleep(10)
        for service in area.user.services:
            if service.name == "Github":
                response = requests.get(
                    url="https://api.github.com/user/repos",
                    headers={
                        "Accept": "application/vnd.github+json",
                        "Authorization": "Bearer " + service.token,
                        "X-GitHub-Api-Version": "2022-11-28"
                    }
                )
                print(response.json())
                for repo in response.json():
                    if repo.get('name') not in repo_old:
                        print("New repo created")
                        reactions[area.reactions[0].name](area)
                        return
###########################################################
def new_doc_created(area):
    doc_old_id = []
    scheduler.remove_job(str(area.id))
    for service in area.user.services:
        if service.name == "Google Docs":
            response = requests.get(
                url="https://www.googleapis.com/drive/v3/files",
                headers={
                    "Accept": "application/vnd.github+json",
                    "Authorization": "Bearer " + service.token,
                    "X-GitHub-Api-Version": "2022-11-28"
                }
            )
            for doc in response.json().get('files'):
                doc_old_id.append(doc.get('id'))
    while True:
        sleep(10)
        for service in area.user.services:
            if service.name == "Google Docs":
                response = requests.get(
                    url="https://www.googleapis.com/drive/v3/files",
                    headers={
                        "Accept": "application/vnd.github+json",
                        "Authorization": "Bearer " + service.token,
                        "X-GitHub-Api-Version": "2022-11-28"
                    }
                )
                for doc in response.json().get('files'):
                    if doc.get('id') not in doc_old_id and doc.get('mimeType') == "application/vnd.google-apps.document":
                        print("New doc created")
                        reactions[area.reactions[0].name](area)
                        return

###########################################################

def dropbox_file_created(area):
    old_nb_files = 0
    scheduler.remove_job(str(area.id))
    for service in area.user.services:
        if service.name == "Dropbox":
            response = requests.post(
                url="https://api.dropboxapi.com/2/files/list_folder",
                headers={
                    "Authorization": "Bearer " + service.token,
                    "Content-Type": "application/json"
                },
                json={
                    "path": "",
                    "recursive": True,
                    "include_media_info": False,
                    "include_deleted": False,
                    "include_has_explicit_shared_members": False,
                    "include_mounted_folders": True,
                    "include_non_downloadable_files": True
                }
            )
            if response.status_code == 200:
                print(response)
            else:
                print("Error while listing files")
                print(response)
                return
            old_nb_files = len(response.json().get('entries'))
    while True:
        sleep(10)
        for service in area.user.services:
            if service.name == "Dropbox":
                response = requests.post(
                    url="https://api.dropboxapi.com/2/files/list_folder",
                    headers={
                        "Authorization": "Bearer " + service.token,
                    },
                    json={
                        "path": "",
                        "recursive": True,
                        "include_media_info": False,
                        "include_deleted": False,
                        "include_has_explicit_shared_members": False,
                        "include_mounted_folders": True,
                        "include_non_downloadable_files": True
                    }
                )
                if len(response.json().get('entries')) > old_nb_files:
                    print("New file created")
                    reactions[area.reactions[0].name](area)
                    return

###########################################################

def astronaut_enter_space(area):
    response = requests.get(
        url="http://api.open-notify.org/astros.json"
    )

    if response.status_code != 200:
        print("Error while getting astronauts")
        return
    response = response.json()
    nb_astronauts = len(response.get('people'))

    while True:
        sleep(10)
        response = requests.get(
            url="http://api.open-notify.org/astros.json"
        )
        if response.status_code != 200:
            print("Error while getting astronauts")
            continue
        response = response.json()
        if len(response.get('people')) > nb_astronauts:
            print("Astronaut entered space")
            reactions[area.reactions[0].name](area)
            return


###########################################################

def astronaut_leave_space(area):
    response = requests.get(
        url="http://api.open-notify.org/astros.json"
    )

    if response.status_code != 200:
        print("Error while getting astronauts")
        return
    response = response.json()
    nb_astronauts = len(response.get('people'))

    while True:
        sleep(10)
        response = requests.get(
            url="http://api.open-notify.org/astros.json"
        )
        if response.status_code != 200:
            print("Error while getting astronauts")
            continue
        response = response.json()
        if len(response.get('people')) < nb_astronauts:
            print("Astronaut left space")
            reactions[area.reactions[0].name](area)
            return

###########################################################

def discord_message(area):
    scheduler.remove_job(str(area.id))
    guild_id = ""
    for user_service in area.user.services:
        if user_service.name == 'Discord':
            guild_id = user_service.token
    print('guild_id', guild_id)
    response = requests.get(
        url="https://discord.com/api/v9/guilds/" + guild_id + "/channels",
        headers={
            "Authorization": "Bot " + environ.get('DISCORD_BOT_TOKEN') or ''
        }
    )
    if response.status_code != 200:
        print("Error while getting channels")
        return
    channels = response.json()
    last_message_id = []
    for channel in channels:
        if channel.get('type') == 0:
            last_message_id.append(channel.get('last_message_id'))
    while True:
        sleep(10)
        response = requests.get(
            url="https://discord.com/api/v9/guilds/" + guild_id + "/channels",
            headers={
                "Authorization": "Bot " + environ.get('DISCORD_BOT_TOKEN') or ''
            }
        )
        if response.status_code != 200:
            print("Error while getting channels")
            continue
        channels = response.json()
        for channel in channels:
            if channel.get('type') == 0 and channel.get('last_message_id') not in last_message_id:
                print("New message")
                reactions[area.reactions[0].name](area)
                return
###########################################################

def temperture_alert(area):
    city = area.actions[0].parameters[0].value
    temp = area.actions[0].parameters[1].value
    temp = float(temp)

    response = requests.get(
        url="http://api.weatherapi.com/v1/current.json?key=" + environ.get('WEATHER_API_KEY') + "&q=" + city
    )
    if response.status_code != 200:
        print("Error while getting temp")
        return
    response = response.json()
    if response.get('current').get('temp_f') >= temp:
        print("Temp reached")
        reactions[area.reactions[0].name](area)

###########################################################

def humidity_alert(area):
    city = area.actions[0].parameters[0].value
    humidity = area.actions[0].parameters[1].value
    humidity = int(humidity)

    response = requests.get(
        url="http://api.weatherapi.com/v1/current.json?key=" + environ.get('WEATHER_API_KEY') + "&q=" + city
    )
    if response.status_code != 200:
        print("Error while getting humidity")
        return
    response = response.json()
    if response.get('current').get('humidity') >= humidity:
        print("Humidity reached")
        reactions[area.reactions[0].name](area)

###########################################################

def wind_speed_alert(area):
    city = area.actions[0].parameters[0].value
    wind_speed = area.actions[0].parameters[1].value
    wind_speed = int(wind_speed)

    response = requests.get(
        url="http://api.weatherapi.com/v1/current.json?key=" + environ.get('WEATHER_API_KEY') + "&q=" + city
    )
    if response.status_code != 200:
        print("Error while getting wind speed")
        return
    response = response.json()
    if response.get('current').get('wind_kph') >= wind_speed:
        print("Wind speed reached")
        reactions[area.reactions[0].name](area)

###########################################################

def new_playlist_created(area):
    old_nb_playlists = 0
    scheduler.remove_job(str(area.id))
    for service in area.user.services:
        if service.name == "Spotify":
            token = service.token
            response = requests.get(
                url="https://api.spotify.com/v1/me/playlists",
                headers={
                    "Authorization": "Bearer " + token,
                }
            )
            if response.status_code == 200:
                print(response)
            else:
                print("Error while listing playlists")
                print(response)
                return
            old_nb_playlists = response.json().get('total')
    while True:
        sleep(10)
        response = requests.get(
            url="https://api.spotify.com/v1/me/playlists",
            headers={
                "Authorization": "Bearer " + token,
            }
        )
        if response.status_code == 200:
            print(response)
        else:
            print("Error while listing playlists")
            print(response)
            return
        if response.json().get('total') > old_nb_playlists:
            print("New playlist created")
            reactions[area.reactions[0].name](area)
            return

actions = {
    "Jour et heure": date_and_time_alert,
    "Tous les jours à": every_day_at,
    "Tous les mois à": every_month_at,
    "Tous les ans à": every_year_at,
    "Croisement cryptomonnaie": crypto_crossing_alert,
    "Croisement forex": forex_crossing_alert,
    "Nouveau dépôt": new_repo_created,
    "Nouveau document": new_doc_created,
    "Nouveau fichier dropbox": dropbox_file_created,
    "Astronaute entre dans l'espace": astronaut_enter_space,
    "Astronaute quitte l'espace": astronaut_leave_space,
    "Message discord": discord_message,
    "Température supérieure à": temperture_alert,
    "Humidité supérieure à": humidity_alert,
    "Vitesse du vent supérieure à": wind_speed_alert,
    "Nouvelle playlist": new_playlist_created
}

######################   REACTIONS   ######################
def send_mail(area, reaction_idx=0):
    msg = MIMEText(area.reactions[reaction_idx].parameters[2].value)
    msg['Subject'] = area.reactions[reaction_idx].parameters[1].value
    msg['From'] = environ.get('MAIL_USERNAME') or 'username'
    msg['To'] = area.reactions[reaction_idx].parameters[0].value
    s = smtplib.SMTP_SSL('smtp.gmail.com', 465)
    try:
        s.login(environ.get('MAIL_USERNAME') or 'username', environ.get('MAIL_PASSWORD') or 'password')
        s.sendmail(environ.get('MAIL_USERNAME') or 'username', area.reactions[reaction_idx].parameters[0].value, msg.as_string())
    except Exception as e:
        print(e)
        print("Error while sending mail")
    area.disable()
    try:
        scheduler.remove_job(str(area.id))
    except:
        pass
    return
###########################################################
def create_repo(area, reaction_idx=0):
    name = area.reactions[reaction_idx].parameters[0].value
    description = area.reactions[reaction_idx].parameters[1].value
    for service in area.user.services:
        if service.name == "Github":
            response = requests.get(
                url="https://api.github.com/user/repos",
                headers={
                    "Accept": "application/vnd.github+json",
                    "Authorization": "Bearer " + service.token,
                    "X-GitHub-Api-Version": "2022-11-28"
                }
            )
            for repo in response.json():
                if repo.get('name') == name:
                    print("Repo already exists")
                    area.disable()
                    scheduler.remove_job(str(area.id))
                    return
            response = requests.post(
                url="https://api.github.com/user/repos",
                headers={
                    "Accept": "application/vnd.github+json",
                    "Authorization": "Bearer " + service.token,
                    "X-GitHub-Api-Version": "2022-11-28"
                },
                json={
                    "name": name,
                    "description": description
                }
            )
            if response.status_code == 201:
                print("Repo created")
            else:
                print("Error while creating repo")
            break
    area.disable()
    try:
        scheduler.remove_job(str(area.id))
    except:
        pass
    return
###########################################################
def create_doc(area, reaction_idx=0):
    name = area.reactions[reaction_idx].parameters[0].value
    folder_name = area.reactions[reaction_idx].parameters[1].value
    
    for service in area.user.services:
        if service.name == "Google Docs":
            # Get folder id
            response = requests.get(
                url="https://www.googleapis.com/drive/v3/files",
                headers={
                    "Authorization": "Bearer " + service.token,
                }
            )
            response = response.json()
            folder_id = ""
            for folder in response.get('files'):
                if folder.get('name') == folder_name and folder.get('mimeType') == "application/vnd.google-apps.folder":
                    folder_id = folder.get('id')
                    break
            if folder_id == "":
                response = requests.post(
                    url="https://www.googleapis.com/drive/v3/files",
                    headers={
                        "Authorization": "Bearer " + service.token,
                    },
                    json={
                        "name": name,
                        "mimeType": "application/vnd.google-apps.document",
                    }
                )
            else:
                response = requests.post(
                    url="https://www.googleapis.com/drive/v3/files",
                    headers={
                        "Authorization": "Bearer " + service.token,
                    },
                    json={
                        "name": name,
                        "mimeType": "application/vnd.google-apps.document",
                        "parents": [folder_id]
                    }
                )
            print(response)
            if response.status_code == 200:
                print("Doc created")
            else:
                print("Error while creating doc")
            break
    area.disable()
    try:
        scheduler.remove_job(str(area.id))
    except:
        pass
    return
###########################################################

def dropbox_create_file(area, reaction_idx=0):
    name = area.reactions[reaction_idx].parameters[0].value
    content = area.reactions[reaction_idx].parameters[1].value

    if name == "":
        name = "cenrtralized"
    if name.find(".") == -1:
        name += ".txt"
    tmp_file = open(name, "w")

    tmp_file.write(content)
    data = open(name, "rb").read()

    for service in area.user.services:
        if service.name == "Dropbox":
            response = requests.post(
                url="https://content.dropboxapi.com/2/files/upload",
                headers={
                    "Authorization": "Bearer " + service.token,
                    "Content-Type": "application/octet-stream",
                    "Dropbox-API-Arg": "{\"path\":\"/centralized/" + name + "\",\"mode\":{\".tag\":\"overwrite\"}}"
                },
                data= data
            )
            if response.status_code == 200:
                print("File created")
            else:
                print(response)
                print("Error while creating file")
            print(response)
            break
    # Delete tmp file
    tmp_file.close()
    area.disable()
    try:
        scheduler.remove_job(str(area.id))
    except:
        pass
    return
###########################################################

def discord_send_message(area, reaction_idx=0):
    channel_name = area.reactions[reaction_idx].parameters[0].value
    message = area.reactions[reaction_idx].parameters[1].value
    guild_id = ""
    for user_service in area.user.services:
        if user_service.name == 'Discord':
            guild_id = user_service.token
    response = requests.get(
        url="https://discord.com/api/v9/guilds/" + guild_id + "/channels",
        headers={
            "Authorization": "Bot " + environ.get('DISCORD_BOT_TOKEN') or ''
        }
    )
    if response.status_code != 200:
        print("Error while getting channels")
        return
    channels = response.json()
    sent = False
    for channel in channels:
        if channel.get('name') == channel_name and channel.get('type') == 0:
            response = requests.post(
                url="https://discord.com/api/v9/channels/" + channel.get('id') + "/messages",
                headers={
                    "Authorization": "Bot " + environ.get('DISCORD_BOT_TOKEN') or ''
                },
                json={
                    "content": message
                }
            )
            if response.status_code != 200:
                print("Error while sending message")
                print(response)
                return
            print(response)
            sent = True
            break
    if not sent:
        for channel in channels:
            if channel.get('type') == 0:
                response = requests.post(
                    url="https://discord.com/api/v9/channels/" + channel.get('id') + "/messages",
                    headers={
                        "Authorization": "Bot " + environ.get('DISCORD_BOT_TOKEN') or ''
                    },
                    json={
                        "content": message
                    }
                )
                if response.status_code != 200:
                    print("Error while sending message")
                    print(response)
                    return
                print(response)
                break
    area.disable()
    try:
        scheduler.remove_job(str(area.id))
    except:
        pass
    return

###########################################################

def skip_song(area, reaction_idx=0):
    for service in area.user.services:
        if service.name == "Spotify":
            token = service.token
            response = requests.post(
                url="https://api.spotify.com/v1/me/player/next",
                headers={
                    "Authorization": "Bearer " + token,
                }
            )
            if response.status_code == 204:
                print("Song skipped")
            else:
                print("Error while skipping song")
                print(response)
            break
    area.disable()
    try:
        scheduler.remove_job(str(area.id))
    except:
        pass
    return

###########################################################

def previous_song(area, reaction_idx=0):
    for service in area.user.services:
        if service.name == "Spotify":
            token = service.token
            response = requests.post(
                url="https://api.spotify.com/v1/me/player/previous",
                headers={
                    "Authorization": "Bearer " + token,
                }
            )
            if response.status_code == 204:
                print("Song skipped")
            else:
                print("Error while skipping song")
                print(response)
                print(response.content)
            break
    area.disable()
    try:
        scheduler.remove_job(str(area.id))
    except:
        pass
    return

###########################################################

def pause_song(area, reaction_idx=0):
    for service in area.user.services:
        if service.name == "Spotify":
            token = service.token
            response = requests.put(
                url="https://api.spotify.com/v1/me/player/pause",
                headers={
                    "Authorization": "Bearer " + token,
                }
            )
            if response.status_code == 204:
                print("Song paused")
            else:
                print("Error while pausing song")
                print(response)
                print(response.content)
            break
    area.disable()
    try:
        scheduler.remove_job(str(area.id))
    except:
        pass
    return

reactions = {
    "Envoyer un mail": send_mail,
    "Créer un dépôt": create_repo,
    "Créer un document": create_doc,
    "Créer un fichier dropbox": dropbox_create_file,
    "Envoyer un message": discord_send_message,
    "Passer à la chanson suivante": skip_song,
    "Passer à la chanson précédente": previous_song,
    "Mettre en pause": pause_song
}