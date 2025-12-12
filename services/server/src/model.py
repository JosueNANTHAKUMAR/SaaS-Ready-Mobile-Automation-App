import requests

class AreaOutOfDb:
    id = None
    enabled = None
    user_id = None
    user = None
    name = None
    description = None
    actions = None
    reactions = None
    
    def __init__(self, area):
        self.id = area.id
        self.enabled = area.enabled
        self.user_id = area.user_id
        self.user = UserOutOfDb(area.user, area)
        self.name = area.name
        self.description = area.description
        self.actions = []
        for action in area.actions:
            self.actions.append(ActionWithValuesOutOfDb(action, area))
        self.reactions = []
        for reaction in area.reactions:
            self.reactions.append(REActionWithValuesOutOfDb(reaction, area))
            
    def disable(self):
        response = requests.post(
            url='http://localhost:5000/login',
            json={
                'email': 'admin@gmail.com',
                'password': 'admin'
            }
        )
        token = response.json().get('access_token')
        response = requests.put(
            url='http://localhost:5000/area/disable/' + str(self.id),
            headers={
                "x-access-tokens": token
            }
        )
        print(response.json())
        return self

class ServiceWithTokenOutOfDb:
    id = None
    name = None
    color = None
    icon = None
    token = None
    service_id = None
    subscribable = None
    actions = None
    reactions = None
    
    def __init__(self, service, area):
        self.id = service.id
        self.name = service.name
        self.color = service.color
        self.icon = service.icon
        self.token = service.token
        self.service_id = service.service_id
        self.subscribable = service.subscribable
        self.actions = []
        for action in service.actions:
            self.actions.append(ActionWithValuesOutOfDb(action, area))
        self.reactions = []
        for reaction in service.reactions:
            self.reactions.append(REActionWithValuesOutOfDb(reaction, area))

class ServiceOutOfDb:
    id = None
    name = None
    color = None
    icon = None
    actions = None
    reactions = None
    subscribable = None
    
    def __init__(self, service):
        self.id = service.id
        self.name = service.name
        self.color = service.color
        self.icon = service.icon
        self.actions = []
        for action in service.actions:
            self.actions.append(ActionOutOfDb(action))
        self.reactions = []
        for reaction in service.reactions:
            self.reactions.append(REActionOutOfDb(reaction))
        self.subscribable = service.subscribable

class ActionOutOfDb:
    id = None
    name = None
    description = None
    service_id = None
    parameters = None
    outputs = None
    
    def __init__(self, action):
        self.id = action.id
        self.name = action.name
        self.description = action.description
        self.service_id = action.service_id
        self.parameters = []
        for parameter in action.parameters:
            self.parameters.append(ParameterOutOfDb(parameter))

class REActionOutOfDb:
    id = None
    name = None
    description = None
    service_id = None
    parameters = None
    
    def __init__(self, reaction):
        self.id = reaction.id
        self.name = reaction.name
        self.description = reaction.description
        self.service_id = reaction.service_id
        self.parameters = []
        for parameter in reaction.parameters:
            self.parameters.append(ParameterOutOfDb(parameter))
            
class ParameterOutOfDb:
    id = None
    name = None
    type = None
    
    def __init__(self, parameter):
        self.id = parameter.id
        self.name = parameter.name
        self.type = parameter.type

class UserOutOfDb:
    id = None
    email = None
    services = None
    
    def __init__(self, user, area):
        self.id = user.id
        self.email = user.email
        self.services = []
        for service in user.services:
            self.services.append(ServiceWithTokenOutOfDb(service, area))
   
class ActionWithValuesOutOfDb:
    id = None
    name = None
    description = None
    service_id = None
    parameters = None
    outputs = None
    
    def __init__(self, action, area):
        self.id = action.id
        self.name = action.name
        self.description = action.description
        self.service_id = action.service_id
        self.parameters = []
        for actionsWithValues in area.actions:
            if actionsWithValues.name == action.name:
                for parameter in actionsWithValues.parameters:
                    self.parameters.append(ParameterWithValuesOutOfDb(parameter))
        
class REActionWithValuesOutOfDb:
    id = None
    name = None
    description = None
    service_id = None
    parameters = None
    
    def __init__(self, reaction, area):
        self.id = reaction.id
        self.name = reaction.name
        self.description = reaction.description
        self.service_id = reaction.service_id
        self.parameters = []
        for reactionsWithValues in area.reactions:
            if reactionsWithValues.name == reaction.name:
                for parameter in reactionsWithValues.parameters:
                    self.parameters.append(ParameterWithValuesOutOfDb(parameter))
        
class ParameterWithValuesOutOfDb:
    id = None
    name = None
    value = None
    type = None
    
    def __init__(self, parameter):
        self.id = parameter.id
        self.name = parameter.name
        self.value = parameter.value
        self.type = parameter.type