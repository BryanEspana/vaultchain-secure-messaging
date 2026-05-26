require 'swagger_helper'

RSpec.describe 'auth', type: :request do

  path '/auth/register' do
    post 'Registra un nuevo usuario' do
      tags 'Auth'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          display_name: { type: :string },
          password: { type: :string },
          password_confirmation: { type: :string }
        },
        required: [ 'email', 'display_name', 'password', 'password_confirmation' ]
      }

      response '201', 'usuario creado' do
        run_test!
      end

      response '422', 'error en creación' do
        run_test!
      end
    end
  end

  path '/auth/login' do
    post 'Inicia sesión de usuario' do
      tags 'Auth'
      consumes 'application/json'
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: [ 'email', 'password' ]
      }

      response '200', 'login exitoso o MFA requerido' do
        run_test!
      end

      response '401', 'credenciales inválidas' do
        run_test!
      end
    end
  end

  path '/auth/mfa/enable' do
    post 'Habilita MFA para un usuario' do
      tags 'Auth'
      consumes 'application/json'
      parameter name: :mfa_req, in: :body, schema: {
        type: :object,
        properties: {
          user_id: { type: :string }
        },
        required: [ 'user_id' ]
      }

      response '200', 'MFA habilitado' do
        run_test!
      end

      response '404', 'usuario no encontrado' do
        run_test!
      end
    end
  end

  path '/auth/mfa/verify' do
    post 'Verifica código MFA' do
      tags 'Auth'
      consumes 'application/json'
      parameter name: :mfa_verify, in: :body, schema: {
        type: :object,
        properties: {
          temp_token: { type: :string },
          code: { type: :string }
        },
        required: [ 'temp_token', 'code' ]
      }

      response '200', 'MFA verificado' do
        run_test!
      end

      response '401', 'código o token inválido' do
        run_test!
      end
    end
  end

end
