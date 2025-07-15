# Internal Messenger

Um sistema de mensageria interna desenvolvido em Ruby on Rails com autenticação JWT e controle de acesso baseado em papéis.

### 🚀 Principais Funcionalidades

- **Autenticação JWT**: Sistema seguro de login/logout com tokens JWT
- **Controle de Acesso**: Diferentes níveis de acesso (admin/employee)
- **Gerenciamento de Usuários**: CRUD completo com ativação/desativação
- **API RESTful**: Endpoints bem documentados para integração
- **Docker**: Ambiente containerizado para desenvolvimento

### 🛠️ Tecnologias Utilizadas

- **Backend**: Ruby on Rails 7.2.2
- **Banco de Dados**: PostgreSQL 15
- **Autenticação**: Devise + JWT
- **Testes**: RSpec + FactoryBot
- **Containerização**: Docker + Docker Compose

## 🚀 Quick Start

### Pré-requisitos

- Docker e Docker Compose instalados
- Git

## 📚 Documentação

Para informações detalhadas sobre instalação, configuração e uso da API, consulte nossa documentação:

- **[📖 Guia de Instalação e Configuração](https://github.com/ViniciusLisboa07/internal-messenger/wiki/Instalando-ambiente-de-desenvolvimento)** - Como configurar o ambiente de desenvolvimento
- **[🔗 Documentação da API](https://github.com/ViniciusLisboa07/internal-messenger/wiki/Documenta%C3%A7%C3%A3o-API)** - Endpoints, autenticação e exemplos de uso

## 🧪 Testes

Execute os testes com:

```bash
 make test
```

Ou execute testes específicos:

```bash
# Testes de modelo
 make test spec/models/

# Testes de controller
 make test spec/controllers/
```

## 📁 Estrutura do Projeto

```
internal-messenger/
├── app/
│   ├── controllers/api/v1/    # Controllers da API
│   ├── models/                # Modelos do banco
│   ├── services/              # Lógica de negócio
│   └── strategies/            # Estratégias de busca/filtro
├── config/                    # Configurações Rails
├── db/                        # Migrações e seeds
├── spec/                      # Testes RSpec
└── docker-compose.yml         # Configuração Docker
```

---

**Desenvolvido com ❤️ por Vinícius Lisboa**
