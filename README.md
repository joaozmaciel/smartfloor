# SmartFloor

Aplicativo Flutter para captura e planejamento de ambientes.

## Requisitos

- Flutter stable com Dart SDK 3.13.7 ou superior.
- Para Android: Android SDK e Java 17.
- Um emulador Android ou dispositivo Android para executar o aplicativo.

Confira a instalacao com `flutter doctor`.

## Configurar e executar

```sh
git clone https://github.com/joaozmaciel/smartfloor.git
cd smartfloor
flutter pub get
flutter run
```

O `pubspec.lock` esta versionado para manter as mesmas versoes das dependencias
em diferentes maquinas.

## Supabase

O app usa o Supabase Auth para login, cadastro e recuperacao de senha. A URL do
projeto e a chave publica `publishable` podem ser substituidas no build:

```sh
flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

A chave publishable e destinada ao cliente. Nunca use a chave `secret` ou
`service_role` no aplicativo. O cadastro envia nome, telefone, WhatsApp, CEP,
cidade e idade como metadados do usuario no Supabase Auth. Com confirmacao de
e-mail habilitada, o usuario precisa confirmar o endereco antes de entrar.

Os projetos ficam vinculados ao usuario autenticado no Supabase. Antes de usar
esse recurso, execute os SQLs da pasta `supabase/migrations` em ordem no SQL
Editor do seu projeto Supabase. Eles criam a tabela, as politicas de acesso e
os campos opcionais das dimensoes do ambiente.

### Assistente de planejamento com Gemini

O assistente chama o Gemini por uma Supabase Edge Function; a chave de API
nao deve ser incluida no app Flutter. Configure o segredo no projeto Supabase
e publique a funcao:

```sh
supabase link --project-ref <project-ref>
supabase secrets set GEMINI_API_KEY=<sua-chave-gemini>
supabase functions deploy smartfloor-assistant
```

Opcionalmente, configure `GEMINI_MODEL` como segredo para escolher outro modelo.
A funcao usa `gemini-2.5-flash` por padrao e mantem a verificacao JWT habilitada.
O assistente recebe apenas a conversa atual e os dados resumidos dos projetos
carregados na tela; as mensagens nao sao persistidas pelo app. A ferramenta de
calculo de area, perimetro e volume valida os valores no servidor.

### Medicao guiada por AR (Android)

O escaneamento usa ARCore e requer Android 7.0 (API 24) ou superior, Google
Play Services para RA e um aparelho compativel. Ele mede distancias entre
pontos indicados pelo usuario; nao reconhece automaticamente o contorno inteiro
do comodo. As estimativas sao editaveis no formulario antes de criar a planta.

## Validar

```sh
flutter analyze
flutter test
```
