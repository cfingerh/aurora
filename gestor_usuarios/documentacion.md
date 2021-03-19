
# Usuarios

No existe propiamente tal, en la base de datos una tabla con los usuarios, sino mas bien una tabla de los usuarios con sus roles, por lo tanto en esas tablas se repiten datos como el rut y el nombre. Por tanto, al momento de modificar uno de esos datos, se deben modificar todos los registros existentes para ese usuario.

Desde la lógica de los datos un usuario podría estar en más de una unidad, pero no me queda claro si desde el punto de vista del gestor tiene sentido.


Mejoras posteriores sugiero modificar, con una tabla de usuarios (sincronizada con LDAP) y otra con las tablas de usuarios/roles.

## Frontend

Se presenta un listado de los usuarios con sus roles. Al agregar o editar un registro se modifica la variable *accion* y dependiendo de eso se muestra el formulario correspondiente


