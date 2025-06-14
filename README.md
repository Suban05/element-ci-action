# Element-ci-action

[![rake](https://github.com/Suban05/element-ci-action/actions/workflows/rake.yml/badge.svg)](https://github.com/Suban05/element-ci-action/actions/workflows/rake.yml)
[![Test Coverage](https://img.shields.io/codecov/c/github/Suban05/element-ci-action.svg)](https://codecov.io/github/Suban05/element-ci-action?branch=main)
[![Hits-of-Code](https://hitsofcode.com/github/suban05/element-ci-action?branch=main&label=Hits-of-Code)](https://hitsofcode.com/github/suban05/element-ci-action/view?branch=main&label=Hits-of-Code)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/Suban05/element-ci-action/blob/main/LICENSE)

**GitHub Action** for automating CI processes in the cloud-based development system [1C:Enterprise.Element](https://1cmycloud.com/).

## Limitations

Before committing, you must build the project using `F9` in the 1C:Element IDE.  
Currently, the control panel API does not support project builds, so this must be done manually.

## Usage Example

```yaml
name: CI

on:
  push:
    branches:
      - main

jobs:
  CI:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run CI
        uses: Suban05/element-ci-action@v0.0.9
        with:
          config: |
            version: 7.0.5-57
            project_id: ${{ vars.PROJECT }}
            login: ${{ secrets.LOGIN }}
            password: ${{ secrets.PASSWORD }}
            branch: ${{ github.ref_name }}
            actions:
              -
                name: Tests
                title: Run tests
                method: post
                path: tests
````

## Arguments

The input parameter `config` must contain a YAML configuration.

| Field        | Description                                                              | Required |
| ------------ | ------------------------------------------------------------------------ | -------- |
| `version`    | 1C\:Element version                                                      | ✅        |
| `project_id` | Project identifier in the control panel                                  | ✅        |
| `login`      | Client ID from the control panel access key                              | ✅        |
| `password`   | Client secret from the control panel access key                          | ✅        |
| `branch`     | Repository branch                                                        | ✅        |
| `head_ref`   | Set if you want to trigger the workflow for a PR                         | ❌        |
| `actions`    | (optional) YAML array with HTTP endpoint requests within the application | ❌        |

---

## Example `actions`

```yaml
actions:
  - name: Tests
    title: Run tests
    method: post
    path: tests
```

* `name`: system name
* `title`: log display message
* `method`: HTTP method (`get`, `post`)
* `path`: endpoint path in the application (e.g., `tests`)

## Workflow

1. A new application is created from the project.
2. If `actions` are defined — requests are sent to the endpoints.
3. If all responses are 200, the process completes successfully.
4. If any step returns a status code other than 200, the CI will fail.
   The application will be deleted in any case to avoid cluttering the application list.

## How to Contribute

To test this action, simply run the following commands (assumes [Ruby](https://www.ruby-lang.org/en/) 3+ is installed on your system):

```bash
bundle
bundle exec rake
```

## Element-ci-action (Russian)

**GitHub Action** для автоматизации CI-процессов в облачной системе разработки [1С:Предприятие.Элемент](https://1cmycloud.com/).

## Ограничения

Перед коммитом нужно обязательно сделать сборку проекта через `F9` в IDE 1С:Элемент.
На текущий момент API панели управления не позволяет делать сборки проекта, поэтому это приходится делать вручную.

## Пример использования

```yaml
name: CI

on:
  push:
    branches:
      - main

jobs:
  CI:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run CI
        uses: Suban05/element-ci-action@v0.0.9
        with:
          config: |
            version: 7.0.5-57
            project_id: ${{ vars.PROJECT }}
            login: ${{ secrets.LOGIN }}
            password: ${{ secrets.PASSWORD }}
            branch: ${{ github.ref_name }}
            actions:
              -
                name: Tests
                title: Run tests
                method: post
                path: tests
```

## Аргументы

Входной параметр `config` должен содержать YAML-конфигурацию.

| Поле         | Описание                                                                  | Обязательно |
| ------------ | ------------------------------------------------------------------------- | ----------- |
| `version`    | Версия 1С:Элемент                                                         | ✅           |
| `project_id` | Идентификатор проекта в панели управления                                 | ✅           |
| `login`      | Client id из ключа доступа панели управления                              | ✅           |
| `password`   | Client secret из ключа доступа панели управления                          | ✅           |
| `branch`     | Ветка репозитория                                                         | ✅           |
| `head_ref`   | Заполняется, если необходим запуск workflow для PR                        | ❌           |
| `actions`    | (опционально) YAML-массив с запросами к HTTP-эндпоинтам внутри приложения | ❌           |

---

## Пример `actions`

```yaml
actions:
  - name: Tests
    title: Run tests
    method: post
    path: tests
```

* `name`: системное имя
* `title`: отображаемое сообщение в логах
* `method`: HTTP-метод (`get`, `post`)
* `path`: путь к эндпоинту в приложении (например, `tests`)

## Сценарий

1. Создаётся новое приложение из проекта.
2. При наличии `actions` — выполняются запросы к эндпоинтам.
3. Если все ответы — 200, процесс успешно завершается.
4. Если любой шаг возвращает код, отличный от 200, — CI завершится с ошибкой.
При этом, приложение в любом случае удалится, чтобы не засорять список приложений.

## Как внести вклад

Чтобы протестировать этот action, просто запустите следующие команды (ожидается, что
[Ruby](https://www.ruby-lang.org/en/) 3+ установлен в вашей системе):

```bash
bundle
bundle exec rake
```
