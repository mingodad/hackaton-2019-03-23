# hackaton-2019-03-23
Implementation of a backend for a hackaton on 2019-03-23

This implementation is done using this scripting language https://github.com/mingodad/squilu

If you want to try it you can get an excutable here https://github.com/mingodad/db-api-server and for example at the command line type "./squilu-release-linux-64 server.nut"

Here is the description for this implementation (in Spanish):



Backend
Desarrollar un página web.

Tecnologías posibles: Java, Python, NodeJs Asp.net , PHP, etc…

Pruebas

1º Montar un servidor web que devuelva en la ruta “/health-check” la hora del servidor web con el formato “23 de marzo de 2019 10:15”

2º Desarrollar una página de bienvenida, devolver por defecto “Hello world!” y si el navegador está configurado en idioma español “¡Hola mundo!” en la ruta “/welcome”

 3º Desarrollar una página simple de login con los campos “email” y “password” y el botón “Enviar”  en la  ruta “/login”

4º Crear la ruta “/check-login” que devuelva error 401 y devuelva este json:  
{status: “error”, code: 401, “message”: “User or password not found”}

5º  Hacer que la ruta anterior valide si el usuario coincide con algunos de los usuarios que aparecen en el JSON  facilitado “users.json” y la contraseña también coincide y redireccionarlo a la página “/welcome” o en caso contrario devolver el error.

6º Listar los productos que aparecen en el fichero /products.json, mostrando título, imagen y precio.

7º Mostrar filtrado por el titulo=apple los productos que aparecen en el fichero /products.json, mostrando título, imagen y precio.
/products?title=apple

8º  Listar los productos que aparecen en el fichero /products.json, mostrando título, imagen y precio, ordenados dependiento de los parámetros _sort y _order.
/products?_sort=price&_order=asc

Materiales facilitados:  http://tiny.cc/hmu190323
users.json
Products.json

