# Nascer+

## Visão Geral do Projeto

O **Nascer+** é um aplicativo moderno e multiplataforma (Mobile/Web) desenvolvido para auxiliar profissionais da área de obstetrícia (obstetras, doulas e parteiras) no gerenciamento, acompanhamento de gestantes e controle financeiro de contratos. 

O projeto conta com integração e sincronização em tempo real com a nuvem via **Firebase** (Autenticação, Firestore e Storage).

---

## Funcionalidades Principais

O aplicativo Nascer+ oferece as seguintes ferramentas integradas:

*   **Autenticação e Acesso Seguro**: Tela de login elegante com design Glassmorphism integrada ao Firebase Auth.
*   **Cadastro de Gestantes**: Registro completo incluindo nome, maternidade, classificação de risco (Risco Habitual ou Alto Risco) e foto de perfil (com suporte para corte e edição).
*   **Cálculo Clínico de DPP**: Calculadora integrada para estimar a Data Provável do Parto (DPP) com base na Data da Última Menstruação (DUM) ou Ultrassonografia.
*   **Ficha de Acompanhamento (Checklist)**: Gerenciamento em cascata de cartões e subtópicos para registrar o progresso do pré-natal. Possui a funcionalidade de **Importar Ficha** para copiar a estrutura de cartões de uma gestante para outra rapidamente.
*   **Histórico de Pós-Parto Detalhado**: Ao registrar o nascimento, o usuário escolhe a data exata através de um seletor de datas (*DatePicker*). O sistema calcula e exibe de forma reativa a contagem de tempo pós-parto (ex: *"1 semana e 2 dias pós-parto"*).
*   **Arquivamento Inteligente**: Gestantes com acompanhamento finalizado podem ser arquivadas para liberar espaço visual na lista principal, mantendo a contagem gestacional/pós-parto e histórico acessíveis na aba de "Arquivadas".
*   **Painel Financeiro Redesenhado**: 
    *   Painel superior estilizado com cabeçalho ondulado gradiente e logo integrada.
    *   Cards de resumo gerenciais: **A Receber** (saldo devedor total) e **Contratos Pendentes** (total aguardando entrega).
    *   Indicadores de progresso de quitação individuais em formato linear com badges coloridas (ex: badge verde de `100%` para quitadas ou rosa para pendentes).
    *   Filtros inteligentes em tempo real (busca textual por gestante/contrato e chave para ocultar ou exibir gestantes quitadas).
    *   Avatares de perfil com coloração de status (tons de verde para contratos quitados e rosa para pendentes).
    *   Ocultamento automático inteligente de grávidas com contratos totalmente quitados da lista financeira padrão.
*   **Notificações Locais Inteligentes**: Lembretes mensais agendados localmente no dispositivo para alertar a profissional no dia exato do vencimento de parcelas de contratos pendentes.
*   **Branding & Splash Screen**: Tela de carregamento personalizada com a logo Nascer+, fundo estilizado e animações suaves de inicialização.

---

## Tecnologias Utilizadas

O Nascer+ é construído utilizando as seguintes tecnologias e pacotes:

*   **Flutter & Dart**: Framework de UI multiplataforma e linguagem de desenvolvimento.
*   **Firebase Suite**:
    *   `firebase_core`: Inicialização da plataforma.
    *   `firebase_auth`: Autenticação segura de usuários.
    *   `cloud_firestore`: Sincronização e persistência de dados em nuvem em tempo real.
    *   `firebase_storage`: Armazenamento de imagens de perfil de forma segura.
*   **Gerenciamento de Notificações**: `flutter_local_notifications` e `timezone` para agendamentos recorrentes e precisos baseados na hora local do dispositivo.
*   **Utilidades Adicionais**:
    *   `intl`: Formatação de moedas (BRL) e datas locais.
    *   `image_picker` & `image_cropper`: Seleção e recorte de fotos.
    *   `url_launcher`: Atalhos para e-mails de feedback e contatos.

---

## Estrutura do Projeto

O projeto segue uma arquitetura baseada em serviços e estados reativos:

```text
lib/
├── firebase_options.dart         # Configurações do Firebase geradas automaticamente
├── main.dart                     # Inicialização de serviços e gerenciamento de rotas
├── models/
│   └── gestante.dart             # Modelos de dados: Gestante, Pagamento e CartaoFicha
├── screens/
│   ├── ajustes_screen.dart       # Tela de configurações e manuais
│   ├── cadastro_screen.dart      # Formulário de cadastro de gestante
│   ├── detalhes_dialogs.dart     # Caixas de diálogo auxiliares (Ex: Importar Ficha)
│   ├── detalhes_pagamento_screen.dart # Detalhes e lançamentos financeiros individuais
│   ├── detalhes_screen.dart      # Ficha médica e checklist de pré-natal
│   ├── editar_gestante_screen.dart # Formulário para atualizar dados da gestante
│   ├── financeiro_screen.dart    # Painel de controle financeiro geral
│   ├── home_screen.dart          # Tela principal (Listagem de Ativas/Arquivadas)
│   └── login_screen.dart         # Tela de autenticação em Glassmorphism
└── services/
    ├── arquiva_gestante.dart     # Regras de arquivamento local/remoto
    ├── calculo_dum.dart          # Cálculo de DPP por Data da Última Menstruação
    ├── calculo_ultra.dart        # Cálculo de DPP por Ultrassom
    ├── edita_gestante.dart       # Fluxo de atualização de cadastros
    ├── ficha_service.dart        # Lógica de atualização em cascata de checklists
    ├── gerencia_parto.dart       # Caixa de diálogo com DatePicker para registrar o nascimento
    ├── gestantes_provider.dart   # Gerenciador de estado (Firebase)
    ├── image_convert_database.dart # Conversão de imagens locais para visualização offline
    ├── image_escolher.dart       # Serviços de câmera e galeria do dispositivo
    └── notification_service.dart # Agendador de lembretes e solicitações de permissão
```

---

## Como Executar o Projeto

### Pré-requisitos
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (versão `>= 3.3.0`) configurado.
*   Emulador Android, iOS, ou navegador Google Chrome habilitado.

### Passos
1.  **Clone o repositório:**
    ```bash
    git clone <URL_DO_REPOSITORIO>
    cd nascermais
    ```
2.  **Instale as dependências:**
    ```bash
    flutter pub get
    ```
3.  **Execute a suíte de testes unitários e de integração:**
    ```bash
    flutter test
    ```
4.  **Execute o aplicativo:**
    *   Para rodar no navegador (Web):
        ```bash
        flutter run -d chrome
        ```
    *   Para rodar em um emulador/dispositivo físico (Android/iOS):
        ```bash
        flutter run
        ```

---

**Desenvolvido com ❤️ para quem vive o nascer.**
