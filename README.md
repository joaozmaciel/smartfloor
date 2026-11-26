# SmartFloor

Aplicativo Flutter para levantamento e análise preliminar de plantas baixas 2D.

## Requisitos

- Git.
- Flutter `>=3.47.0` e Dart `^3.13.0` (use a mesma versão mínima do CI para reproduzir as validações).
- Para Android: Android SDK, dispositivo/emulador configurado e Java 17.
- Um projeto Supabase com Auth, banco PostgreSQL e Storage habilitados.

Confira a instalação do Flutter e as licenças do Android SDK:

```sh
flutter doctor
flutter doctor --android-licenses
```

O alvo de execução documentado e validado pelo CI é Android. Para compilar iOS é necessário macOS com Xcode; Windows e Linux exigem suas toolchains nativas correspondentes.

## Configurar e executar

1. Clone o repositório e entre na pasta do projeto:

```sh
git clone https://github.com/joaozmaciel/smartfloor.git
cd smartfloor
```
2. Na raiz do projeto, instale as dependências e crie sua configuração local:

PowerShell:

```powershell
flutter pub get
Copy-Item env.example.json env.json
```

macOS/Linux:

```sh
flutter pub get
cp env.example.json env.json
```

3. No painel do Supabase, crie/abra o projeto e copie a **Project URL** e a **publishable key** para `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` em `env.json`. Não coloque valores reais em `env.example.json`.
4. Configure o banco e o Storage conforme a seção abaixo.
5. Execute no Android:

```sh
flutter run --dart-define-from-file=env.json
```

Para selecionar um dispositivo específico, use `flutter devices` e passe seu ID com `flutter run -d <device-id> --dart-define-from-file=env.json`.

`env.json` é local e ignorado pelo Git. Cada clone precisa criá-lo. O cliente usa somente a publishable key; nunca use chaves `secret` ou `service_role` no aplicativo. A configuração de Auth (por exemplo, confirmação de e-mail e URLs de redirecionamento, se habilitadas) deve corresponder ao ambiente do projeto Supabase.

## Banco de dados e Storage

Em um projeto Supabase novo, abra o **SQL Editor** no painel e execute integralmente os arquivos abaixo, na ordem apresentada. Cada arquivo deve ser executado uma única vez nesse banco:

1. `supabase/migrations/20261125160500_create_projects.sql`
2. `supabase/migrations/20261126090000_projects_persistence.sql`

A segunda migração configura a persistência completa, RLS e o bucket privado `project-backgrounds`. O bucket permite imagens JPEG, PNG, WebP e PDF; o limite de tamanho efetivo continua sujeito aos limites do plano/configuração do Supabase. Os arquivos usam o caminho `<user_id>/<project_id>/background`. A aplicação não envia `user_id`; o banco associa cada projeto ao usuário autenticado. As políticas RLS limitam leitura, gravação e exclusão aos projetos do próprio usuário e aos arquivos dentro da pasta do usuário.

Se o projeto Supabase já tiver dados, faça backup e revise o estado do schema antes de aplicar mudanças. Não execute essas instruções de banco de desenvolvimento sobre produção sem uma revisão e um plano de migração.

`projects.data` guarda um documento JSON versionado (`version: 1`) com `floorPlan` (terreno e cômodos definidos pela lista ordenada de vértices em metros), `background` (origem, escala, arquivo e caminho no Storage) e `analysis` (dados do terreno e parâmetros municipais). Áreas e perímetros são recalculados a partir dos vértices; as colunas de área e quantidade de cômodos são resumos para a listagem. Alertas e PDFs são gerados novamente e não são persistidos.

```json
{
  "version": 1,
  "floorPlan": {
    "name": "Casa",
    "lot": { "name": "Terreno", "vertices": [{ "x": 0, "y": 0 }, { "x": 10, "y": 0 }, { "x": 10, "y": 20 }, { "x": 0, "y": 20 }] },
    "rooms": [{ "name": "Sala", "vertices": [{ "x": 1, "y": 1 }, { "x": 5, "y": 1 }, { "x": 5, "y": 4 }, { "x": 1, "y": 4 }] }]
  },
  "background": {
    "captureMode": "imageOrPdf",
    "wasPdf": false,
    "fileName": "planta.png",
    "storagePath": "<user_id>/<project_id>/background",
    "originX": 0,
    "originY": 0,
    "metersPerPixel": 0.0123
  },
  "analysis": {
    "site": { "widthM": 10, "lengthM": 20, "frontSetbackM": 5, "leftSetbackM": 1 },
    "settings": { "minFrontSetbackM": 0, "minSideSetbackM": 0, "minRearSetbackM": 0, "maxOccupancyPercent": 0 }
  }
}
```

`lot`, `background`, `analysis` e `background.storagePath` podem ser `null`. Cada polígono real deve ter pelo menos três vértices.

O cadastro grava nome, telefone, WhatsApp, CEP, cidade, idade e a versão/data de aceite dos termos como metadados do usuário do Supabase Auth. A senha é enviada somente ao fluxo de autenticação e nunca é salva em uma tabela da aplicação.

## Validar

```sh
dart analyze
flutter test
flutter build apk --debug
```

Esses três comandos também são executados automaticamente pelo GitHub Actions em push e pull request para `main` e `master`. O CI não precisa das credenciais do Supabase: os testes usam configurações/repositórios isolados e o app recebe a configuração somente ao ser executado localmente.
