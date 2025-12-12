from flask import jsonify, Blueprint, request
from . import Service, ServiceWithToken, User
from . import db
from .token import token_required
from os import environ
import requests

serviceManagement = Blueprint('servicesManagement', __name__)

auth_urls = {
    'Github': "https://github.com/login/oauth/authorize/?client_id=" + str(environ.get('GITHUB_ID') or '') + "&redirect_uri=http://localhost:8081/callback&scope=repo",
    'GoogleOauth': "https://accounts.google.com/o/oauth2/v2/auth?client_id=" + str(environ.get('GOOGLE_ID') or '') + "&redirect_uri=http://localhost:8081/callback&response_type=code&scope=https://www.googleapis.com/auth/userinfo.email",
    'Google Docs': 'https://accounts.google.com/o/oauth2/v2/auth?client_id=' + str(environ.get('GOOGLE_ID') or '') + '&redirect_uri=http://localhost:8081/callback&response_type=code&scope=https://www.googleapis.com/auth/drive',
    'Dropbox': "https://www.dropbox.com/oauth2/authorize?client_id=" + str(environ.get('DROPBOX_ID') or '') + "&redirect_uri=http://localhost:8081/callback&response_type=code&scope=account_info.read files.content.write file_requests.read files.content.read files.metadata.read",
    'Discord': "https://discord.com/oauth2/authorize?client_id=" + str(environ.get('DISCORD_ID') or '') + "&scope=bot&permissions=2048&redirect_uri=http%3A%2F%2Flocalhost%3A8081%2Fcallback&response_type=code",
    'Spotify': "https://accounts.spotify.com/authorize?client_id=" + str(environ.get('SPOTIFY_ID') or '') + "&response_type=code&redirect_uri=http://localhost:8081/callback&scope=user-read-private user-read-email user-read-playback-state user-modify-playback-state user-read-currently-playing user-read-recently-played user-top-read user-library-read user-library-modify playlist-read-private playlist-read-collaborative playlist-modify-public playlist-modify-private streaming app-remote-control user-follow-read user-follow-modify",
}

code_urls = {
    'Github': "https://github.com/login/oauth/access_token",
    'GoogleOauth': "https://oauth2.googleapis.com/token",
    'Google Docs': "https://oauth2.googleapis.com/token",
    'Dropbox': "https://api.dropboxapi.com/oauth2/token",
    'Discord': "https://discord.com/api/oauth2/token",
    'Spotify': "https://accounts.spotify.com/api/token"
}

icons = {
    "bitcoin": '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24"><path d="M360-120v-80H240v-80h80v-400h-80v-80h120v-80h80v80h80v-80h80v85q52 14 86 56.5t34 98.5q0 29-10 55.5T682-497q35 21 56.5 57t21.5 80q0 66-47 113t-113 47v80h-80v-80h-80v80h-80Zm40-400h160q33 0 56.5-23.5T640-600q0-33-23.5-56.5T560-680H400v160Zm0 240h200q33 0 56.5-23.5T680-360q0-33-23.5-56.5T600-440H400v160Z"/></svg>',
    "dropbox": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 43 40" version="1.1" height="40px"><path d="m12.5 0l-12.5 8.1 8.7 7 12.5-7.8-8.7-7.3zm-12.5 21.9l12.5 8.2 8.7-7.3-12.5-7.7-8.7 6.8zm21.2 0.9l8.8 7.3 12.4-8.1-8.6-6.9-12.6 7.7zm21.2-14.7l-12.4-8.1-8.8 7.3 12.6 7.8 8.6-7zm-21.1 16.3l-8.8 7.3-3.7-2.5v2.8l12.5 7.5 12.5-7.5v-2.8l-3.8 2.5-8.7-7.3z"/></svg>',
    "euro_symbol": '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24"><path d="M600-120q-118 0-210-67T260-360H120v-80h122q-2-11-2-20v-40q0-9 2-20H120v-80h140q38-106 130-173t210-67q69 0 130.5 24T840-748l-70 70q-35-29-78.5-45.5T600-740q-75 0-136.5 38.5T370-600h230v80H344q-2 11-3 20t-1 20q0 11 1 20t3 20h256v80H370q32 63 93.5 101.5T600-220q48 0 92.5-16.5T770-282l70 70q-48 44-109.5 68T600-120Z"/></svg>',
    "github": '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>',
    "google_docs": '<svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" width="100" height="100" viewBox="0 0 50 50"><path d="M 41.707031 13.792969 L 30.207031 2.292969 C 30.019531 2.105469 29.765625 2 29.5 2 L 11.492188 2 C 9.566406 2 8 3.5625 8 5.480469 L 8 43.902344 C 8 46.160156 9.84375 48 12.113281 48 L 37.886719 48 C 40.15625 48 42 46.160156 42 43.902344 L 42 14.5 C 42 14.234375 41.894531 13.980469 41.707031 13.792969 Z M 26 38 L 17 38 L 17 36 L 26 36 Z M 33 34 L 17 34 L 17 32 L 33 32 Z M 33 30 L 17 30 L 17 28 L 33 28 Z M 33 26 L 17 26 L 17 24 L 33 24 Z M 31.667969 14 C 30.746094 14 30 13.253906 30 12.332031 L 30 4.914063 L 39.085938 14 Z"></path></svg>',
    "email": '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24"><path d="M160-160q-33 0-56.5-23.5T80-240v-480q0-33 23.5-56.5T160-800h640q33 0 56.5 23.5T880-720v480q0 33-23.5 56.5T800-160H160Zm320-280L160-640v400h640v-400L480-440Zm0-80 320-200H160l320 200ZM160-640v-80 480-400Z"/></svg>',
    "date_range": '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24"><path d="M200-80q-33 0-56.5-23.5T120-160v-560q0-33 23.5-56.5T200-800h40v-80h80v80h320v-80h80v80h40q33 0 56.5 23.5T840-720v560q0 33-23.5 56.5T760-80H200Zm0-80h560v-400H200v400Zm0-480h560v-80H200v80Zm0 0v-80 80Zm280 240q-17 0-28.5-11.5T440-440q0-17 11.5-28.5T480-480q17 0 28.5 11.5T520-440q0 17-11.5 28.5T480-400Zm-160 0q-17 0-28.5-11.5T280-440q0-17 11.5-28.5T320-480q17 0 28.5 11.5T360-440q0 17-11.5 28.5T320-400Zm320 0q-17 0-28.5-11.5T600-440q0-17 11.5-28.5T640-480q17 0 28.5 11.5T680-440q0 17-11.5 28.5T640-400ZM480-240q-17 0-28.5-11.5T440-280q0-17 11.5-28.5T480-320q17 0 28.5 11.5T520-280q0 17-11.5 28.5T480-240Zm-160 0q-17 0-28.5-11.5T280-280q0-17 11.5-28.5T320-320q17 0 28.5 11.5T360-280q0 17-11.5 28.5T320-240Zm320 0q-17 0-28.5-11.5T600-280q0-17 11.5-28.5T640-320q17 0 28.5 11.5T680-280q0 17-11.5 28.5T640-240Z"/></svg>',
    "weather": '<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24"><path d="M440-760v-160h80v160h-80Zm266 110-56-56 113-114 56 57-113 113Zm54 210v-80h160v80H760Zm3 299L650-254l56-56 114 112-57 57ZM254-650 141-763l57-57 112 114-56 56Zm-14 450h180q25 0 42.5-17.5T480-260q0-25-17-42.5T421-320h-51l-20-48q-14-33-44-52.5T240-440q-50 0-85 35t-35 85q0 50 35 85t85 35Zm0 80q-83 0-141.5-58.5T40-320q0-83 58.5-141.5T240-520q60 0 109.5 32.5T423-400q58 0 97.5 43T560-254q-2 57-42.5 95.5T420-120H240Zm320-134q-5-20-10-39t-10-39q45-19 72.5-59t27.5-89q0-66-47-113t-113-47q-60 0-105 39t-53 99q-20-5-41-9t-41-9q14-88 82.5-144T480-720q100 0 170 70t70 170q0 77-44 138.5T560-254Zm-79-226Z"/></svg>',
    "space": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" id="space"><path d="M29.39 40.48a107.92 107.92 0 0 0 13.38 4 15.48 15.48 0 0 1-26.15-9.52 109 109 0 0 0 12.77 5.52Zm.69-1.88a100.19 100.19 0 0 1-13.53-6 15.3 15.3 0 0 1 3.19-8.76q.47-.6 1-1.17c.16-.17.33-.34.5-.5A15.32 15.32 0 0 1 32 17.78a15.5 15.5 0 0 1 15.4 13.86 14.57 14.57 0 0 1 .09 1.63v.67a15.29 15.29 0 0 1-3.19 8.78 102.49 102.49 0 0 1-14.22-4.12Zm-6.29-13.35a11.68 11.68 0 0 1 10.05-3.32A1 1 0 0 0 35 21.1a1 1 0 0 0-.84-1.1 13.83 13.83 0 0 0-2.16-.22 13.59 13.59 0 0 0-9.66 4.08 1 1 0 0 0 0 1.41 1 1 0 0 0 1.41 0Zm-7.23 9V32.59c-.68-.36-1.32-.72-1.93-1.09C8.92 28.16 6 25.25 6.48 24c.36-1 3.64-1.83 11.09-.55A15.77 15.77 0 0 1 19 21.64c-5.53-1-13.13-1.78-14.37 1.64-1 2.88 3.3 6.78 9.94 10.5.61.34 1.23.68 1.88 1l.2.1q0-.3-.06-.6Zm32.94-1.48v.5a17.14 17.14 0 0 1-.08 1.73c6.47 3.77 8.51 6.55 8.14 7.56-.25.68-2.28 1.66-8.31.95-.89-.11-1.82-.24-2.78-.41L45 42.86h-.12l-.52-.11c-.12.16-.24.31-.37.46a15 15 0 0 1-1.08 1.17l-.08.08c.79.17 1.54.33 2.29.47a2.2 2.2 0 0 1-.2.23l.21-.23c1.38.26 2.69.47 3.93.61a34 34 0 0 0 4 .27c3.66 0 5.81-.85 6.42-2.52 1.2-3.42-5.01-7.71-9.98-10.52Zm2.37-14.27a5.7 5.7 0 1 0-5.69-5.69 5.7 5.7 0 0 0 5.69 5.69ZM34 11.42a.92.92 0 1 0-.92-.92.92.92 0 0 0 .92.92Zm-13-3a.92.92 0 1 0-.92-.92.92.92 0 0 0 .92.92ZM51.08 25.5a.92.92 0 1 0 .92-.92.92.92 0 0 0-.92.92ZM60 22.42a.92.92 0 1 0-.92-.92.92.92 0 0 0 .92.92Zm0 9.16a.92.92 0 1 0 .92.92.92.92 0 0 0-.92-.92Zm-56 0a.92.92 0 1 0 .92.92.92.92 0 0 0-.92-.92Zm5 10a.92.92 0 1 0 .92.92.92.92 0 0 0-.92-.92Zm-3 8a.92.92 0 1 0 .92.92.92.92 0 0 0-.92-.92Zm41 0a.92.92 0 1 0 .92.92.92.92 0 0 0-.92-.92Zm6 5a.92.92 0 1 0 .92.92.92.92 0 0 0-.92-.92ZM12 15.42a.92.92 0 1 0-.92-.92.92.92 0 0 0 .92.92Zm8.89-1.92A1.11 1.11 0 1 0 22 12.39a1.11 1.11 0 0 0-1.11 1.11ZM13 48.39a1.11 1.11 0 1 0 1.11 1.11A1.11 1.11 0 0 0 13 48.39Zm21 7a1.11 1.11 0 1 0 1.11 1.11A1.11 1.11 0 0 0 34 55.39Zm5-46.78a1.11 1.11 0 1 0-1.11-1.11A1.11 1.11 0 0 0 39 8.61Z"></path></svg>',
    "discord": '<svg viewBox="-1.5 0 24 24" xmlns="http://www.w3.org/2000/svg"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"><path d="m13.93 11.4c-.054.633-.582 1.127-1.224 1.127-.678 0-1.229-.55-1.229-1.229s.55-1.229 1.228-1.229c.683.029 1.225.59 1.225 1.277 0 .019 0 .037-.001.056v-.003zm-5.604-1.33c-.688.061-1.223.634-1.223 1.332s.535 1.271 1.218 1.332h.005c.683-.029 1.225-.59 1.225-1.277 0-.019 0-.037-.001-.056v.003c.001-.02.002-.043.002-.067 0-.685-.541-1.243-1.219-1.269h-.002zm12.674-7.598v21.528c-3.023-2.672-2.057-1.787-5.568-5.052l.636 2.22h-13.609c-1.359-.004-2.46-1.106-2.46-2.466 0-.002 0-.004 0-.006v-16.224c0-.002 0-.004 0-.006 0-1.36 1.101-2.462 2.459-2.466h16.081c1.359.004 2.46 1.106 2.46 2.466v.006zm-3.42 11.376c-.042-2.559-.676-4.96-1.77-7.086l.042.09c-.924-.731-2.088-1.195-3.358-1.259l-.014-.001-.168.192c1.15.312 2.15.837 3.002 1.535l-.014-.011c-1.399-.769-3.066-1.222-4.839-1.222-1.493 0-2.911.321-4.189.898l.064-.026c-.444.204-.708.35-.708.35.884-.722 1.942-1.266 3.1-1.56l.056-.012-.12-.144c-1.284.065-2.448.529-3.384 1.269l.012-.009c-1.052 2.036-1.686 4.437-1.728 6.982v.014c.799 1.111 2.088 1.826 3.543 1.826.041 0 .082-.001.123-.002h-.006s.444-.54.804-.996c-.866-.223-1.592-.727-2.093-1.406l-.007-.01c.176.124.468.284.49.3 1.209.672 2.652 1.067 4.188 1.067 1.191 0 2.326-.238 3.36-.668l-.058.021c.528-.202.982-.44 1.404-.723l-.025.016c-.526.703-1.277 1.212-2.144 1.423l-.026.005c.36.456.792.972.792.972.033.001.072.001.111.001 1.461 0 2.755-.714 3.552-1.813l.009-.013z"></path></g></svg>',
    "spotify": '<svg height="200px" width="200px" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 305 305" xml:space="preserve"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <g id="XMLID_85_"> <path id="XMLID_86_" d="M152.441,0C68.385,0,0,68.39,0,152.453C0,236.568,68.385,305,152.441,305 C236.562,305,305,236.568,305,152.453C305,68.39,236.562,0,152.441,0z M75.08,208.47c17.674-5.38,35.795-8.108,53.857-8.108 c30.676,0,60.96,7.774,87.592,22.49c1.584,0.863,3.024,3.717,3.67,7.27c0.646,3.552,0.389,7.205-0.648,9.105 c-1.309,2.438-3.965,4.014-6.768,4.014c-1.389,0-2.61-0.312-3.831-0.972c-24.448-13.438-52.116-20.542-80.015-20.542 c-16.855,0-33.402,2.495-49.167,7.409c-0.768,0.233-1.558,0.352-2.348,0.352c-3.452,0.001-6.448-2.198-7.453-5.461 C68.612,219.566,71.419,209.667,75.08,208.47z M68.43,152.303c19.699-5.355,40.057-8.071,60.508-8.071 c36.765,0,73.273,8.896,105.601,25.739c2.266,1.15,3.936,3.1,4.701,5.49c0.776,2.421,0.542,5.024-0.669,7.347 c-2.885,5.646-6.257,9.44-8.393,9.44c-1.514,0-2.975-0.363-4.43-1.09c-30.019-15.632-62.59-23.558-96.811-23.558 c-19.035,0-37.71,2.503-55.489,7.435c-0.827,0.224-1.676,0.337-2.521,0.337c-4.277,0.001-8.046-2.888-9.162-7.013 C60.336,162.994,63.601,153.616,68.43,152.303z M66.727,115.606c-0.903,0.223-1.826,0.335-2.744,0.335 c-5.169,0.001-9.648-3.492-10.892-8.487c-1.559-6.323,2.397-13.668,8.126-15.111c22.281-5.473,45.065-8.248,67.72-8.248 c43.856,0,85.857,9.86,124.851,29.312c2.708,1.336,4.727,3.642,5.687,6.493c0.96,2.854,0.748,5.926-0.592,8.64 c-1.826,3.655-5.772,7.59-10.121,7.59c-1.677,0-3.399-0.393-4.924-1.109c-35.819-17.921-74.477-27.008-114.9-27.008 C108.164,108.014,87.234,110.568,66.727,115.606z"></path> </g> </g></svg>'
}

@serviceManagement.route('/services/icons', methods=['GET'])
@token_required
def get_icons(current_user):
    return jsonify(icons), 200

@serviceManagement.route('/services/icon/<string:icon_name>', methods=['GET'])
@token_required
def get_icon(current_user, icon_name):
    return jsonify({"icon": icons[icon_name]}), 200

@serviceManagement.route('/services', methods=['GET'])
@token_required
def get_services(current_user):
    services = db.session.query(Service).all()
    print([service.serialize() for service in services])
    return jsonify([service.serialize() for service in services]), 200

@serviceManagement.route('/services/<int:service_id>', methods=['GET'])
@token_required
def get_service(current_user, service_id):
    service = db.session.query(Service).filter_by(id=service_id).first()
    if not service:
        return jsonify({"error": "Service not found"}), 404
    return jsonify(service.serialize()), 200

@serviceManagement.route('/auth/services/<int:service_id>', methods=['GET'])
@token_required
def get_auth_url(current_user, service_id):
    service = db.session.query(Service).filter_by(id=service_id).first()
    if not service:
        return jsonify({"error": "Service not found"}), 404
    return jsonify({"url": auth_urls[service.name]}), 200

@serviceManagement.route('/auth/services', methods=['POST'])
@token_required
def get_token(current_user):
    if not request.json:
        return jsonify({"error": "No data provided"}), 400
    if not request.json.get('code'):
        return jsonify({"error": "No code provided"}), 400
    if not request.json.get('id'):
        return jsonify({"error": "No service_id provided"}), 400
    service = db.session.query(Service).filter_by(id=request.json.get('id')).first()
    serviceWithToken = ServiceWithToken(service, current_user.id)
    if service.name == 'Google Docs':
        code = request.json.get('code').strip("&scope").replace('%2F', '/')
    elif service.name == 'Discord':
        code = request.json.get('code').split('&')[0]
    else:
        code = request.json.get('code')
    response = requests.post(
        url=code_urls[service.name],
        data={
            'client_id': environ.get(service.name.upper().replace(' ', '_') + '_ID'),
            'client_secret': environ.get(service.name.upper().replace(' ', '_') + '_SECRET'),
            'code': code,
            'redirect_uri': 'http://localhost:8081/callback',
            'grant_type': 'authorization_code'
        },
        headers={'Accept': 'application/json'}
    ) if service.name != 'Discord' else requests.post(
        url=code_urls[service.name],
        data={
            'code': code,
            'redirect_uri': 'http://localhost:8081/callback',
            'grant_type': 'authorization_code',
        },
        headers={'Accept': 'application/x-www-form-urlencoded'},
        auth=(environ.get(service.name.upper().replace(' ', '_') + '_ID') or '', environ.get(service.name.upper().replace(' ', '_') + '_SECRET') or '')
    )
    if service.name == 'Discord':
        guilds_id = response.json().get('guild').get('id')
        print(guilds_id)  
        serviceWithToken.set_token(guilds_id)
    else:
        token = response.json().get('access_token')
        serviceWithToken.set_token(token)
    current_user.services.append(serviceWithToken)
    db.session.commit()
    return jsonify({"token": serviceWithToken.token}), 200

@serviceManagement.route('/auth/register/url', methods=['GET'])
def get_register_url():
    return jsonify({"url": auth_urls['GoogleOauth']}), 200

@serviceManagement.route('/auth/register', methods=['POST'])
def oauth_register():
    if not request.json:
        return jsonify({"error": "No data provided"}), 400
    if not request.json.get('code'):
        return jsonify({"error": "No code provided"}), 400
    code = request.json.get('code').strip("&scope").replace('%2F', '/')
    response = requests.post(
        url=code_urls['GoogleOauth'],
        data={
            'client_id': environ.get('GOOGLE' + '_ID'),
            'client_secret': environ.get('GOOGLE' + '_SECRET'),
            'code': code,
            'redirect_uri': 'http://localhost:8081/callback',
            'grant_type': 'authorization_code'
        },
        headers={'Accept': 'application/json'}
    )
    print(response.json())
    access_token = response.json().get('access_token')
    response = requests.get(
        url="https://www.googleapis.com/oauth2/v2/userinfo",
        headers={'Authorization': 'Bearer ' + access_token}
    )
    print(response.json())
    user = db.session.query(User).filter_by(email=response.json().get('email')).first()
    if not user:
        response = requests.post(
            url="http://localhost:5000/register",
            json={
                'email': response.json().get('email'),
                'password': response.json().get('id')
            },
            headers={'Accept': 'application/json'}
        )
        print(response.json())
    else:
        response = requests.post(
            url="http://localhost:5000/login",
            json={
                'email': response.json().get('email'),
                'password': response.json().get('id')
            },
            headers={'Accept': 'application/json'}
        )
        print(response.json())
    return jsonify(response.json()), 200
