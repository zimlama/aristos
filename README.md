<div>

# Escenario 2: Ejercicio Práctico - Despliegue de una Aplicación Web Sencilla

</div>

<div class="page-body">

**Configuración de la Infraestructura con Terraform (AWS)**

Para la implementación utilicé **AWS** en lugar de GCP, siguiendo el mismo objetivo del escenario: desplegar una aplicación web sencilla utilizando IaC.

1.  **Credenciales y perfil AWS**
    - Se generó un Access Key y se configuró un perfil dedicado:

      ``` code
      aws configure —profile web-app
      ```

    <!-- -->

    - Imagen del Access Key creado en el IAM Users leonardo.admin.aws
      <figure id="28191892-6feb-8031-bb85-c8e4eef4d8f2" class="image">
      <a href="Escenario%202%20Ejercicio%20Pr%C3%A1ctico%20-%20Despliegue%20de%20una%20281918926feb80689048db8433c86ed5/image.png"><img src="./assets/Escenario 2 Ejercicio Práctico - Despliegue de una 281918926feb80689048db8433c86ed5/image.png" style="width:2560px" /></a>
      </figure>

    <!-- -->

    - Imagen del la ejecucion del comando en CLI para crear un profile especifico de uso
      <figure id="28191892-6feb-80d7-9828-db03da799458" class="image">
      <a href="Escenario%202%20Ejercicio%20Pr%C3%A1ctico%20-%20Despliegue%20de%20una%20281918926feb80689048db8433c86ed5/image%201.png"><img src="./assets/Escenario 2 Ejercicio Práctico - Despliegue de una 281918926feb80689048db8433c86ed5/image 1.png" style="width:2560px" /></a>
      </figure>

<!-- -->

2.  **Definición de infraestructura en Terraform**
    - Se creó un archivo `main.tf` que define:
      - Uso del perfil `web-app` para autenticación.

      <!-- -->

      - Una instancia **EC2** con Ubuntu, destinada a funcionar como servidor web.

      <!-- -->

      - Configuración de seguridad (reglas de firewall) permitiendo tráfico HTTP/HTTPS desde cualquier IP (`0.0.0.0/0`).

      <!-- -->

      - Se define la variable para usar el profile definido en el item 1. de codigo :

        ``` code
        variable "aws_profile" {
          type        = string
          description = "Perfil de credenciales AWS (archivo ~/.aws/credentials)"
          default     = "web-app"
        }
        ```

      <!-- -->

      - 

      <!-- -->

      - 

<!-- -->

3.  **Ejecución de Terraform**
    - Inicialización y despliegue:

      ``` code
      terraform init
      terraform plan
      terraform apply
      ```

    <!-- -->

    - Imagen de ejecucion del `terraform init`
      <figure id="28191892-6feb-80e7-848f-d9f6e2aca897" class="image">
      <a href="Escenario%202%20Ejercicio%20Pr%C3%A1ctico%20-%20Despliegue%20de%20una%20281918926feb80689048db8433c86ed5/image%202.png"><img src="./assets/Escenario 2 Ejercicio Práctico - Despliegue de una 281918926feb80689048db8433c86ed5/image 2.png" style="width:2560px" /></a>
      </figure>

    <!-- -->

    - Imagen de ejecucion del `terraform plan`
      <figure id="28191892-6feb-807d-947f-c895920433b5" class="image">
      <a href="Escenario%202%20Ejercicio%20Pr%C3%A1ctico%20-%20Despliegue%20de%20una%20281918926feb80689048db8433c86ed5/image%203.png"><img src="./assets/Escenario 2 Ejercicio Práctico - Despliegue de una 281918926feb80689048db8433c86ed5/image 3.png" style="width:2560px" /></a>
      </figure>

    <!-- -->

    - Imagen de ejecucion del `terraform apply`
      <figure id="28191892-6feb-808c-8cbb-f1675b0834dc" class="image">
      <a href="Escenario%202%20Ejercicio%20Pr%C3%A1ctico%20-%20Despliegue%20de%20una%20281918926feb80689048db8433c86ed5/image%204.png"><img src="./assets/Escenario 2 Ejercicio Práctico - Despliegue de una 281918926feb80689048db8433c86ed5/image 4.png" style="width:2560px" /></a>
      </figure>

------------------------------------------------------------------------

### **Despliegue de la Aplicación y Verificación**

1.  **Servidor Web**
    - Una vez creada la instancia EC2, se accedió por **SSH** para instalar **Nginx**.

    <!-- -->

    - Se configuró un archivo `index.html` con el mensaje de bienvenida.

<!-- -->

2.  **Accesos disponibles**

    - URL HTTP: [http://ec2-13-222-227-80.compute-1.amazonaws.com](http://ec2-13-222-227-80.compute-1.amazonaws.com/)

    <!-- -->

    - URL HTTPS: [https://ec2-13-222-227-80.compute-1.amazonaws.com](https://ec2-13-222-227-80.compute-1.amazonaws.com/)

    <!-- -->

    - Public IP: `13.222.227.80`

    Se validó el acceso web desde un navegador confirmando la correcta publicación del servicio.

------------------------------------------------------------------------

### **Evidencias y Recursos Entregados**

- **Repositorio con IaC (Terraform .tf):** <https://github.com/zimlama/aristos>

<!-- -->

- **Pruebas de conectividad:** acceso exitoso vía HTTP y HTTPS.
  <figure id="28191892-6feb-80f3-b08a-cd0a6e053461">
  <div class="source">
  <a href="https://www.notion.soundefined"></a>
  </div>
  </figure>

<!-- -->

- **Acceso SSH:** comprobado satisfactoriamente a la instancia EC2.
  <figure id="28191892-6feb-8022-b0f4-d1ad2cb96ade">
  <div class="source">
  <a href="https://www.notion.soundefined"></a>
  </div>
  </figure>

------------------------------------------------------------------------

</div>

<span class="sans" style="font-size:14px;padding-top:2em"></span>
