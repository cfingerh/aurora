# from datetime import datetime
# import collections
# from collections import Counter

# from django.shortcuts import render
# from twilio.jwt.access_token import AccessToken
# from twilio.jwt.access_token.grants import ChatGrant
# from twilio.rest import Client
# import json
# from django.contrib.auth.decorators import login_required
# from django.conf import settings
# from django.http import HttpResponse, JsonResponse, HttpResponseForbidden
# from django.views.decorators.csrf import csrf_exempt
# from django.core.mail import EmailMultiAlternatives
# from django.template.loader import render_to_string
# from django.utils.html import strip_tags

# from django.contrib.auth.models import User
# from base.models import Canal
# from rest_framework_simplejwt.authentication import JWTAuthentication

# from base.utils import randomString


# def getUser(request):
#     aut = JWTAuthentication()
#     user = aut.authenticate(request)[0]
#     return user


# def authenticateDjango(func):
#     def wrapper(request):
#         aut = JWTAuthentication()
#         identity = request.GET.get("identity")
#         validacion = aut.authenticate(request)
#         if validacion is None:
#             return JsonResponse({'message': "Usuario not authorized " + identity}, status=400)

#         if identity and validacion[0].username != identity:
#             return JsonResponse({'message': "Usuario not authorized 2"}, status=400)
#         return func(request)

#     return wrapper


# def getService():
#     account_sid = settings.TWILIO.get('ACCOUNT_SID')
#     chat_service_sid = settings.TWILIO.get('CHAT_SERVICE_SID')
#     auth_token = settings.TWILIO.get('AUTH_TOKEN')
#     client = Client(account_sid, auth_token)
#     service = client.chat.services(chat_service_sid)

#     return service


# @login_required
# def index(request):
#     context = {}
#     return render(request, 'base/base.html', context)


# def getToken(request):
#     identity = request.GET.get("identity")
#     if identity is None:
#         return "No Ingresó Identity"

#     service = getService()
#     user = service.users.get(identity).fetch()

#     tipo = json.loads(user.attributes)["tipo"]
#     if tipo == 'funcionario':
#         authenticateDjango(request, identity=identity)

#     return getTokenString(identity)


# def getTokenString(identity):
#     account_sid = settings.TWILIO.get('ACCOUNT_SID')
#     api_key = settings.TWILIO.get('API_KEY')
#     api_secret = settings.TWILIO.get('API_SECRET')
#     chat_service_sid = settings.TWILIO.get('CHAT_SERVICE_SID')
#     token = AccessToken(account_sid, api_key, api_secret, identity=identity)

#     chat_grant = ChatGrant(service_sid=chat_service_sid)
#     token.add_grant(chat_grant)

#     return HttpResponse(token.to_jwt().decode('utf-8'))


# @csrf_exempt
# def addMemberToChannel(request):
#     """Añade un member al channel respectivo"""

#     account_sid = settings.TWILIO.get('ACCOUNT_SID')
#     chat_service_sid = settings.TWILIO.get('CHAT_SERVICE_SID', None)
#     auth_token = settings.TWILIO.get('AUTH_TOKEN')

#     client = Client(account_sid, auth_token)
#     service = client.chat.services(chat_service_sid)

#     content = json.loads(request.body)

#     try:
#         service.users.get(content["identity"]).fetch()

#         member = service.channels(content['channelSid']).members.create(identity=content["identity"])
#         data = {
#             'memberSid': member.sid
#         }
#         return JsonResponse(data)

#     except:
#         return "Usuario no existe"


# @csrf_exempt
# def createUserAndChannel(request):
#     """Crea el usuario; crea el channel correspondiente"""

#     account_sid = settings.TWILIO.get('ACCOUNT_SID')
#     chat_service_sid = settings.TWILIO.get('CHAT_SERVICE_SID', None)
#     auth_token = settings.TWILIO.get('AUTH_TOKEN')

#     client = Client(account_sid, auth_token)
#     service = client.chat.services(chat_service_sid)

#     content = json.loads(request.body)
#     identity = randomString(30)

#     try:
#         service.users.get(identity).fetch()
#         return "Usuario ya existe"
#     except:
#         pass

#     user = service.users.create(identity=identity)
#     role = [i for i in service.roles.list() if i.friendly_name == "ciudadano deployment"][0]
#     attributes = {"tipo": "ciudadano", "login_content": content}
#     user.update(role_sid=role.sid,
#                 attributes=json.dumps(attributes),
#                 friendly_name=content["nombre"] or 'Sin Nombre')
#     user = user.fetch()

#     user = service.users.get(identity).fetch()
#     user_channels = user.user_channels.list()
#     if len(user_channels) > 0:
#         return HttpResponseForbidden("Ya existe canal para ese usuario")

#     friendly_name = identity
#     if content["nombre"] and len(content["nombre"]) > 0:
#         friendly_name = content["nombre"]

#     channel = service.channels.create(
#         type='private',
#         friendly_name=friendly_name)
#     channel.update(attributes=json.dumps({"login_content": content,
#                                           "status": "desatendido"}))
#     channel.members.create(identity=user.identity)
#     channel = channel.fetch()

#     for member in channel.members.list():
#         if member.identity == identity:
#             role = [i for i in service.roles.list() if i.friendly_name == "ciudadano channel"][0]
#             member.update(role_sid=role.sid)

#     # canalizador = get_canalizador(service.users)

#     # # moidficar: revisar antes si es quyq exist en vez de oucpar try
#     # try:
#     #     channel.members.create(identity=canalizador.identity)
#     # except:
#     #     pass

#     # Crear Usuario Django
#     djangouser = User.objects.get_or_create(
#         sid=user.sid,
#         username=identity)[0]
#     datos = {'created': {'user_data': content,
#                          'datetime': datetime.now().strftime('%s'),
#                          'datetime_pretty': str(datetime.now().strftime('%s'))}
#              }
#     if content["email"] and len(content["email"]) > 5:
#         datos["email"] = content["email"]

#     if content["telefono"] and len(content["telefono"]) > 5:
#         datos["telefono"] = content["telefono"]

#     if content["nombre"] and len(content["nombre"]) > 0:
#         datos["nombre"] = content["nombre"]

#     canal = Canal.objects.get_or_create(sid=channel.sid)[0]
#     datos = {
#         'created': {
#             'datetime': datetime.now().strftime('%s'),
#             'datetime_pretty': str(datetime.now().strftime('%s'))},
#         'user_created': {
#             'user_id': djangouser.id,
#             'user_sid': user.sid}}
#     canal.datos = datos
#     canal.save()

#     djangouser.datos = datos
#     djangouser.save()

#     base_url = 'http://localhost:8080/chat/'
#     contenido = {
#         'nombre': content["nombre"],
#         'identity': identity,
#         'channelSid': channel.sid,
#         'base_url': base_url,
#         'email': content["email"]
#     }
#     send_email(contenido)

#     data = {
#         'identity': identity,
#         'channelSid': channel.sid,
#     }

#     return JsonResponse(data)


# def send_email(data):
#     subject = 'Chat'
#     from_email = settings.DEFAULT_FROM_EMAIL
#     to = data['email']
#     template = 'base/email.html'
#     url = data['base_url'] + data['channelSid'] + '/' + data['identity']
#     html_content = render_to_string(template, {
#                                     'nombre_usuario': data['nombre'],
#                                     'url': url
#                                     })
#     text_content = strip_tags(html_content)

#     msg = EmailMultiAlternatives(subject, text_content, from_email, [to])
#     msg.attach_alternative(html_content, "text/html")
#     msg.send()


# def getDesatendidos(request):
#     authenticateDjango(request)
#     datos = []
#     service = getService()
#     for channel in service.channels.list():
#         dato = json.loads(channel.attributes)
#         # if dato["status"] != 'desatendido':
#         #     continue
#         dato["created"] = channel.date_created.strftime('%s')
#         dato["created_pretty"] = str(channel.date_created)
#         dato["sid"] = channel.sid
#         dato["members_count"] = channel.members_count
#         dato["messages_count"] = channel.messages_count
#         datos.append(dato)

#     return JsonResponse(datos, safe=False)


# def getFuncionarios(request):
#     authenticateDjango(request)
#     datos = []
#     service = getService()
#     for user in service.users.list():
#         dato = json.loads(user.attributes)
#         if dato["tipo"] == 'funcionario':
#             datos.append(dato)
#     return JsonResponse(datos, safe=False)


# def getChannels(request):
#     # Obtiene los channels y miembros de cada channel
#     authenticateDjango(request)
#     datos = []
#     service = getService()
#     for channel in service.channels.list():
#         dato = json.loads(channel.attributes)
#         dato["created"] = channel.date_created.strftime('%s')
#         dato["created_pretty"] = str(channel.date_created)
#         dato["sid"] = channel.sid
#         dato["members_count"] = channel.members_count
#         dato["messages_count"] = channel.messages_count
#         members = service.channels(channel.sid).members.list()
#         datos_member = []
#         for member in members:
#             dato_member = {}
#             dato_member["sid"] = member.sid
#             dato_member["identity"] = member.identity
#             dato_member["date_created"] = member.date_created
#             dato_member["last_consumption_timestamp"] = member.last_consumption_timestamp
#             datos_member.append(dato_member)
#         dato["members"] = datos_member
#         datos.append(dato)
#     return JsonResponse(datos, safe=False)


# def getResumen(request):
#     # Obtiene los channels y miembros de cada channel
#     authenticateDjango(request)
#     dates = []
#     service = getService()
#     dato = {}
#     dato['messages_date'] = []
#     dato['messages_date_count'] = []
#     dato["canales"] = len(service.channels.list())
#     dato["usuarios"] = len(service.users.list())
#     dato["messages_count"] = 0
#     dato['canal_asignado'] = 0
#     dato['canal_desatendido'] = 0
#     for channel in service.channels.list():
#         for message in service.channels(channel.sid).messages.list():
#             dates.append(str(message.date_created.date()))
#         attributes = json.loads(channel.attributes)
#         dato["messages_count"] = dato["messages_count"] + channel.messages_count
#         if attributes["status"] == 'asignado':
#             dato['canal_asignado'] = dato['canal_asignado'] + 1
#         else:
#             dato['canal_desatendido'] = dato['canal_desatendido'] + 1
#     c  = dict(Counter(dates))
#     c = collections.OrderedDict(sorted(c.items()))
#     c = dict(c)
#     # c.sort(key = lambda date: datetime.strptime(date, '%Y-%m-%d'))
#     for item in c:
#         dato['messages_date'].append(item)
#         dato['messages_date_count'].append(c[item])
#     return JsonResponse(dato, safe=False)
