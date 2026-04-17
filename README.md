# VaultChain Secure Messaging 🔐

Prototipo funcional de un sistema de mensajería segura con cifrado de extremo a extremo, firmas digitales y trazabilidad mediante Blockchain.

## 🚀 Requisitos Previos

Este proyecto está diseñado para correr en **Ubuntu (WSL)**. Asegúrate de tener:

*   **Ruby:** 3.3.11
*   **Rails:** 7.2.2
*   **PostgreSQL** instalado y corriendo en WSL.

## 🛠️ Configuración Inicial

Sigue estos pasos para levantar el proyecto desde cero:

### 1. Clonar el repositorio e instalar gemas
```bash
bundle install
```

### 2. Configurar la base de datos
```bash
rails db:create
rails db:migrate
```


### 3. Iniciar el servidor
```bash
rails server
```
El servidor estará disponible en `http://localhost:3000`.

## 🛡️ Funcionalidades Destacadas

*   **Autenticación Segura:** Registro y login mediante JWT.
*   **Generación de Llaves:** Cada usuario tiene un par de llaves RSA-2048.
*   **Cifrado Asimétrico:** Mensajes cifrados con la llave pública del destinatario.
*   **Firmas Digitales:** Verificación de autenticidad mediante firmas ECDSA.
*   **Trazabilidad:** Registros inmutables en la Blockchain local.

## 📋 Arquitectura de Seguridad

El proyecto implementa un modelo de confianza híbrido:

1.  **Identidad (Users):**
    *   `public_key`: Llave pública RSA para cifrado.
    *   `encrypted_private_key`: Llave privada cifrada con AES-256-GCM usando un KDF.
    *   `totp_secret`: Secreto para autenticación de dos factores.

2.  **Transacciones (Transactions):**
    *   `sender_public_key` / `receiver_public_key`: Verificación de identidad.
    *   `digital_signature`: Firma del contenido para integridad.
    *   `block_hash`: Hash que enlaza con la cadena de bloques.

## 🧪 Testing

Las pruebas están configuradas en el directorio `spec`. Para ejecutar el suite de pruebas:

```bash
rails spec
```
Esto verificará que todos los módulos criptográficos funcionan correctamente.
