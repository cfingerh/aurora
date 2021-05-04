import ldap
import ldap.modlist as modlist


class LDAP():

    def __init__(self, usuario):
        self.con = ldap.initialize('ldap://54.207.252.22')
        self.con.set_option(ldap.OPT_REFERRALS, 0)
        self.usuario = usuario
        self.dc_general = u"dc=app,dc=local"
        self.cn = "cn={}".format(usuario)
        self.cn_completo = "{},{}".format(self.cn, self.dc_general)

        self.con.simple_bind_s('cn=admin,dc=app,dc=local', 'gest1469')

    def usuarioExists(self):
        result = self.con.search_s(self.dc_general, ldap.SCOPE_SUBTREE, u"({})".format(self.cn))
        if len(result) == 0:
            raise Exception("Usuario no existe")

    def testPassword(self, password):
        self.usuarioExists()
        try:
            self.con.simple_bind_s(self.cn_completo, password)
        except:
            return False

        return True

    def changePassword(self, password):
        self.usuarioExists()
        self.con.passwd_s(self.cn_completo, None, password)

    def createUsuario(self):
        attrs = {}
        attrs['objectclass'] = [b'inetOrgPerson', b'organizationalPerson', b'person']
        attrs['sn'] = [str.encode(self.usuario)]
        attrs['userPassword'] = b'DifferentSecret'
        ldif = modlist.addModlist(attrs)
        self.con.add(self.cn_completo, ldif)

    def temp(self):
        con.simple_bind_s('cn=fingerhuth,dc=app,dc=local', 'gest1469')
        results = con.search_s(u'dc=app,dc=local', ldap.SCOPE_SUBTREE, u"(cn=fingerhuth)")
        print(results)

        con.simple_bind_s('cn=christian,dc=app,dc=local', 'gest1469')
        results = con.search_s(u'dc=app,dc=local', ldap.SCOPE_SUBTREE, u"(cn=christian)")
        print(results)

        dn = "cn=christian,dc=app,dc=local"
        con.delete(dn)

        attrs = {}
        attrs['objectclass'] = [b'inetOrgPerson', b'organizationalPerson', b'person']
        # attrs['uid'] = [b'10000']
        # attrs['gid'] = [b'10000']
        attrs['sn'] = [b'fingerhuth']
        # attrs['cn'] = 'christian'
        attrs['userPassword'] = b'DifferentSecret'
        # attrs['loginShell'] = [b'/bin/bash']
        # attrs['homeDirectory'] = [b'/home/christian']

        ldif = modlist.addModlist(attrs)

        con.add_s(dn, ldif)

        con.unbind_s()
