

Aplicativo Flutter simples para consumir uma API fake de tarefas, permitindo listar, adicionar, marcar como concluída e remover itens.

## Funcionalidades


- Adição de tarefa via `POST` fake.
- Alternância de status (concluída / não concluída) ao tocar no item.
- Remoção com `swipe to delete` (`Dismissible`) + chamada `DELETE` fake.
- Estados de carregamento e erro com opção de tentar novamente.

## Estrutura do projeto

```text
lib/
  models/
    task.dart
  services/
    task_service.dart
  screens/
    task_list_screen.dart
  widgets/
    task_item.dart
  main.dart
```

## Escolhas técnicas

- **Gerenciamento de estado:** `setState` (simples e suficiente para o escopo do desafio júnior).
- **HTTP:** pacote `http` para requisições REST.
- **UX:**
  - `CircularProgressIndicator` durante carregamento.
  - mensagem de erro amigável e botão para recarregar.
  - `RefreshIndicator` para atualização manual da lista.
  - `Dismissible` para exclusão por gesto.

## Como rodar

### Pré-requisitos

- Flutter 3.x
- Dart 3.x

### Passos

1. Clone este repositório.
2. Instale as dependências:

```bash
flutter pub get
```

3. Rode o app:

```bash
flutter run
```

## Prints da aplicação


