# Uma arquitetura simples para aplicativos Flutter

https://pub.dev/packages/simple_architecture

https://github.com/kodel-dynamics/simple_architecture

## Objetivos

### Reusabilidade

Certas partes de um aplicativo são comuns a vários aplicativos como, por exemplo, autenticação. O que difere são apenas certas configurações, como `clientId` ou `redirectUri` que são específicos para cada aplicativo. Logo, não há por que escrever o mesmo código para diversas aplicações. 

É necessário que partes comuns de um aplicativo sejam reaproveitáveis em outros aplicativos com *nenhuma* alteração e, ao mesmo tempo, permitir que as partes que fazem o serviço de fato sejam intercambiáveis, ou seja, se uma autenticação é feita com os packages `sign_in_with_apple` e `firebase_auth` e, por qualquer motivo (como um package melhor ser construído no futuro ou, por um requisito de um cliente ser necessário utilizar o Amazon Cognito ou Auth0), estas partes devem ser substituíveis sem que nenhuma outra parte do aplicativo ou do código reutilizável seja alterada.

Isso é possível através do conceito de repositórios. Embora a definição do repositório seja específica para bancos de dados (https://martinfowler.com/eaaCatalog/repository.html), nada impede do mesmo conceito ser utilizado para qualquer operação que realize E/S, como leitura e escrita de arquivos, chamadas remotas via REST ou GraphQL e acesso a packages de terceiros, como `firebase_auth`. Então, qualquer parte do sistema que se comunique de alguma forma a qualquer parte externa do sistema é feita através de um contrato (interface) que especifica o que aquele componente faz (para autenticação, basicamente é necessário saber o usuário autenticado, entrar e sair de uma conta). Então as partes do sistema que são intercambiáveis apenas são implementações de tais interfaces e adaptações para as entidades que o sistema entende (por exemplo, há uma classe que guarda informações do usuário, como id, nome, e-mail e url de foto (avatar)). A interface de autenticação pede esta classe de representação de um usuário, então é tarefa da implementação tornar o que ela considera um usuário para a entidade que o aplicativo entende (ou seja, é função do repositório converter o que representa um usuário para ele (ex.: `User` para `firebase_auth`) na entidade que a aplicação entende.

Este objetivo é cumprido com duas funcionalidades da biblioteca: serviços e injeção de dependência.

### Unidades de características (feature)

Quando falamos de S.O.L.I.D., o "S" remete a **responsabilidade única** (*single responsability*). Infelizmente, "responsabilidade" é algo muito vago. Autenticação é uma responsabilidade única? Autenticação normalmente possui vários componentes, como entrar em uma conta, sair de uma conta, verificar o usuário autenticado, se estiver, persistir o usuário autenticado, cuidar de tokens, etc.

Para tornar as coisas extremamente claras, é necessário que tais responsabilidades sejam realmente únicas: ao invés de uma grande responsabilidade "autenticação", é necessário criar uma pasta para agrupar todas as pequenas características que compõe um sistema de autenticação. Cada característica sendo algo a ser implementado que faça somente aquilo (ou seja, em um aplicativo que possui um sistema de autenticação, temos *features* como *entrar*, *sair*, *alterar nome do usuário*, *alterar foto do usuário*, etc. São características distintas que não interferem em outras características e, idealmente, podem ser implementadas em diferentes momentos (i.e.: não preciso completar *entrar* para *alterar nome do usuário* e vice-versa).

Este objetivo é cumprido com uma granulação de *features* através de pastas e arquivos organizados, um sistema de eventos para especificar o que se deseja (ex.: `SignInUser(AuthProvider.google)`) para requisitar entrar com um usuário, utilizando o Google para tal, ou `ChangeUserName(user.id, newName)` para requisitar a alteração do nome de um usuário e um mediador para entender e implementar tais eventos. Este mediador tem acesso ao mesmo sistema de injeção de dependências utilizados em serviços, de forma que ele se torna uma receita de bolo simples de como implementar tal *feature*, utilizando serviços externos para garantir isso (ou seja, neste ponto, há apenas regras de negócio, nenhum tipo de conhecimento de serviços externos, como Firebase Auth, e dependências injetáveis, de forma que tal implementação possa ser facilmente testada).

### Configurações

Quando partes do sistema são reaproveitáveis, geralmente o que difere a utilização são configurações. Por exemplo, em um sistema de autenticação, temos certas configurações, como *Google Client Id*, *Apple Service Id*, *Apple Redirect Uri*, etc.

Embora tais configurações possam ser injetadas em dependências através de parâmetros (durante o registro da dependência), muitas vezes podemos ter configurações variáveis (como, por exemplo, uma preferência salva em `shared_preferences` ou configurações mutáveis através do Firebase Remote Config.

Este objetivo é cumprido com um sistema de injeção de dependência de classes que armazenam configurações e que possuem mecanismos para atualização destas configurações no injetor de dependência.

### Estado

Muito se discute sobre gerenciamento de estado em Flutter. Frameworks gigantescos (e extremamente complexos) são construídos ao redor disto, como BLoC e Riverpod. O problema é que estado é algo simples: sequer é necessário um framework para gerenciamento de estado em Flutter, já que a biblioteca disponibiliza inúmeras formas de manter estados globais e locais sem precisar de packages externos, como `InheritedWidget`, `InheritedModel`, `ChangeNotifier`, `ValueNotifier<T>` e `Stream<T>`. Por exemplo, no Firebase Auth, existe um `Stream<User?>` que dispara durante a inicialização e sempre que um usuário entra ou sai. Qualquer parte do sistema que dependa de um usuário estar autenticado ou que mostre uma informação de tal usuário (como, por exemplo, sua foto) precisa tão somente escutar as mudanças escritas neste stream, com um `StreamBuilder`. E estados são simples assim. Nada mais avançado é necessário na grande maioria dos casos.

Este objetivo é cumprido com um sistema de gerenciamento de estado simples, baseado em `ValueNotifier<T>` (utilizável na UI com um `ValueListenableBuilder<T>(valueListenable: $state.get<AuthState>(), builder: (context, authenticatedUser) => authenticatedUser == null ? LoginPage() : HomePage())`). Como o gerenciador de estado participa do sistema de injeção de dependências, ele pode ter dependências injetadas e pode ser injetado em outros serviços.

Para garantir que um estado tem um valor válido durante a inicialização da app, estes estados devem ser inicializados durante a inicialização da app e seus valores iniciais devem ser carregados. Para cumprir este requisito, o gerenciador de estado tem métodos `load` e `save`, onde `load` carrega um estado (que pode ser um valor padrão fixo ou um valor lido de um banco de dados local, por exemplo, para manter o estado que a app tinha durante a última rodada) e `save` que pode ser implementado (ou ignorado) para salvar o estado atual da aplicação para que ela volte no mesmo estado anterior quando for reiniciada. Adicionalmente, um método `change` é utilizado para mudar o estado que o gerenciador possui (assim disparando os eventos necessários para que o `ValueListenableBuiler<T>` gere um rebuild, no caso do estado ser diferente do anterior.

### Overseers

Muitas vezes, precisamos ver ou cuidar de certas coisas que nossos serviços não podem fazer (ou não deveriam fazer, pelo princípio de responsabilidade única, ou pelo fato de ser incômodo adicionar um monitoramento em cada chamada ou *feature* existente, criando assim duplicidade de código).

Coisas que seriam interessantes de serem implementadas: um gerenciamento de exceções central, onde toda exceção é mostrada, tanto localmente quanto remotamente (com serviços como Sentry ou Firebase Crashlytics). Um sistema que permita medir quanto tempo cada *feature* do sistema demora para ser executada, para verificar gargalos ou até mesmo anomalias, talvez com serviços remotos, tais como o Firebase Performance. Logs de auditoria, para saber exatamente o que foi chamado, qual as entradas e saídas para aquela chamada, etc. 

Para cumprir este objetivo, existem classes chamadas `PipelineBehavior` que interceptam cada chamada do sistema para adicionar tais características. Cada pipeline tem um número de prioridade (de 0 a infinito, sendo 0 executado antes). Então podemos criar pipelines que encapsulam todas chamadas de serviços em um `try/catch` e, caso alguma exceção ocorra, enviem esta, por exemplo, ao Firebase Crashlytics. Da mesma forma, um pipeline com prioridade bem alta (digamos 1000), sendo executado imediatamente antes do *handler* da chamada de fato com um medidor de tempo gasto usando o `Stopwatch`.

### S.O.L.I.D. (sólido)

Os princípios S.O.L.I.D. são muito comuns em projetos escritos por pessoas mais graduadas e com mais experiência. Embora nem todos os aspectos de cada parte deste princípio façam sentido hoje em dia, alguns são extremamente indispensáveis:

1) **S**: *Single responsability*: Conforme descrito acima, cada regra de negócio escrita deve cuidar de uma e somente uma responsabilidade. Quanto mais granular, mais classes existirão, mas mais fácil será localizar e corrigir problemas. Quanto menos granular, mais responsabilidades um módulo terá e maiores chances de problemas, embora menos classes existirão. A quantidade final de código útil (que implementa a solução ao problema) não difere pela granulação.
2) **O**: *Open-Closed principle*: Basicamente, um sistema deve ser aberto a modificações (ex.: implementar um Auth0 ao invés de um Firebase Auth) sem que nada mais no sistema mude. Para que mais nada no sistema mude, as *features* precisam ser fechadas (*closed*). Nesta biblioteca, utilizamos o *Polymorphic open-closed principle* que nada mais é do que a liberdade (*open*) de implementar as coisas como bem desejar, mas ter um contrato fixo para que o aplicativo não precise mudar para acomodar tais mudanças (*closed*) através das interfaces injetadas nas regras de negócios.
3) **L**: *Liskov substitution principle*: Basicamente diz que uma classe pode ser substituída por outra classe que faz parte de sua cadeia de herança sem que o sistema quebre por isso. Este princípio é utilizado no exemplo de autenticação por uma limitação do sistema de dependências: temos uma parte do sistema de autenticação que é a autenticação OAuth com um provedor externo (Google, Facebook, Apple, etc.). Cada provedor tem que ser registrado, mas não podemos ter uma interface para ambos (pois o injetor de dependências registra um tipo de interface por cada implementação). Logo, precisamos criar uma interface do tipo `IOAuthService` e duas interfaces que herdam aquela como `IGoogleOAuthService` e `IAppleOAuthService`. Todas estas interfaces podem ser intercambiadas sem que nada quebre, pois elas não vão adicionar ou remover características (pelo menos em questão a quem as utiliza: a biblioteca). Isso representa exatamente o mesmo que a covariância em Dart, implementada mais comumente em `InheritedWidgets`, onde o método que deve ser sobrescrito `updateShouldNotify` vêm com uma covariância (isto é: o novo tipo que você está criando pode - e deve - ser substituído neste *override* e nada quebrará por isso: `bool updateShouldNotify(covariant InheritedWidget oldWidget)`.
4) **I**: *Interface segregation principle*: Este princípio é sobre quebrar certas funcionalidades que determinadas classes possuem de forma granular: ao invés de um grande contrato que especifica várias funcionalidades que podem nem serem utilizáveis por um destino, a segregação quebra tais funcionalidades em partes menores. Por exemplo, em serviços, temos interfaces puramente decorativas que seguem este princípio, como `IInitializable` que exige a implementação de `void initialize()` e `IBootable` que exige a implementação de `Future<void> initializeAsync()` em partes distintas do sistema (a primeira é executada toda vez que uma classe injetada é instanciada, a segunda é específica para *singletons* e é executado durante o processo de inicialização da biblioteca). Um exemplo de não seguimento deste princípio seria colocar ambos os métodos de inicialização na mesma interface, fazendo com que as classes que as implementam passem a ignorar tais decorações implementando métodos vazios (ou seja, se você tem um método vazio em uma classe só porque uma interface requer isso, essa interface não está seguindo o príncípio de segregação de interfaces).
5) **D**: *Dependency inversion principle*: Este princípio é o que permite escrever código modular, fazendo com que as partes comuns (lógica) possam ser compartilhadas e escritas somente uma vez e os detalhes de implementação sejam livres para serem implementados de forma diferente para cada projeto ou até mesmo serem alteradas em um mesmo projeto sem prejuízo de funcionalidade ou reescrita. A injeção de dependência é utilizada em todos os aspectos desta biblioteca.

### Y.A.G.N.I.

*You ain't gonna need it* é um princípio que diz que você não deve implementar algo (ou deixar pontas para implementar no futuro) de algo que não utilizará no momento. Este requisito é cumprido com *features* granulares que implementam pouco e são independentes, de forma que não é necessário implementar outras partes só por implementar ou deixar pontas de implementação futuras em uma *feature*.

### D.R.Y. (seco)

*Don't Repeat Yourself* é um princípio que diz que você não deve repetir uma linha sequer de código para implementar mais de uma funcionalidade. Este requisito é cumprido com os *pipeline behaviors* para implementar uma vez características utilizadas em vários pontos (em contrapartida a, por exemplo, adicionar tratamento de erros em cada uma das *features* separadamente). E se uma for esquecida? E se você quiser adicionar funcionalidade como, por exemplo, reportar o erro ocorrido ao Firebase Crashlytics? Se mais de um ponto no código deve ser alterado para cumprir este objetivo, então o código não está D.R.Y.

### Exceções como controle de fluxo

Exceções quase sempre são utilizadas como controle de fluxo, ao invés de representar um erro do qual não podemos nos recuperar. Por exemplo, o package `sign_in_with_apple` gera uma exceção do tipo `SignInWithAppleAuthorizationException` com o código `AuthorizationErrorCode.canceled` quando o usuário cancela o fluxo de autenticação. Isso não é algo bom, pois isso não é um erro. O fluxo do programa é interrompido e transferido para uma cláusula `catch` ou, pior, se nenhum `catch` estiver no contexto, o aplicativo simplesmente para de funcionar, só porque o usuário desistiu de entrar com uma conta Apple!

Em Flutter, existe um problema adicional em se utilizar exceções, quando estamos trabalhando com Flutter Web: certas exceções, como `SocketException` estão presentes em um módulo que não devemos importar neste ambiente (`dart:io`). Fazer com que nosso código reaproveitável dependa de verificações extras se estamos no modo web ou não pode se tornar algo bem trabalhoso. 

Adicionalmente, existem exceções que representam o mesmo erro, mas são disparadas por diferentes exceções: por exemplo, quando não há internet disponível e tentamos acessar algo remoto, podemos receber um `SocketException`, um `DioException` se estivermos utilizando `dio` ou, no caso de autenticação, um `FirebaseAuthException` ou mesmo um `PlatformException`. Tudo se resume à mesma falha: `networkRequestFailed` e deveria ser mais fácil de lidar com isso na UI: ao invés de tratar 4 tipos de exceções diferentes (e outras no futuro quando mais funcionalidade for implementada), os serviços poderiam apenas retornar um "carregador de resultado", ou seja, uma classe que contém um estado de sucesso, com o valor devolvido pelo serviço (por exemplo, o usuário autenticado) ou um estado de falha, que contém apenas uma descrição da falha (como, por exemplo, um `enum SignInFailure` que contém todos os problemas que podem ocorrer durante a autenticação e um `unknown` para qualquer outra coisa inesperada). Assim, em nossa UI (ou em qualquer outro ponto), não dependemos de classes e exceções, mas um simples enum (que é muito iteressante pois o Dart nos avisa quando tentamos usar um enum em um `switch` e não cobrimos todas as possibilidades existentes).

Para isso, podemos utilizar uma classe do tipo `Result<TValue, TFailure extends Enum>()` com os construtores `Result.success(TValue value)` e `Result.failure(TFailure failure, [Object? exception, StackTrace? stackTrace])`.

## Um exemplo prático

Como exemplo, vamos implementar um sistema completo de autenticação, utilizando esta biblioteca e todos os conceitos existentes.

## Especificação

* A autenticação será feita exclusivamente através de OAuth usando Google ou Apple (pois toda pessoa que possui um celular obrigatoriamente tem uma conta Google (Android) ou Apple (iOS)). A autenticação Apple deverá funcionar no Android e vice-versa (caso o usuário tenha um iPhone no momento da primeira utilização e no futuro decidiu trocar o aparelho por um Android ou vice-versa).
* No momento, os packages escolhidos para autenticação são `sign_in_with_apple`, `google_sign_in` e `firebase_auth`, mas queremos que tais packages sejam implementados como *plugins*, ou seja, se um dia o `sign_in_with_apple` for descontinuado ou outro package melhor for lançado, podemos realizar a alteração sem precisar alterar absolutamente nada no sistema.
* As regras de negócio devem ser reutilizáveis para outros aplicativos escritos no futuro.
* A autenticação deve ser persistida em um banco de dados local, guardando a data/hora em que o usuário entrou no aplicativo, bem como os dados que foram utilizados (como id do usuário e método de autenticação).
* Como a autenticação pode ser demorada, a UI deverá reportar cada estágio da mesma (aguardando provedor OAuth, aguardando Firebase, aguardando bando de dados, etc.)

## Estrutura do projeto

![image](https://github.com/kodel-dynamics/simple_architecture/assets/379339/c6c83ee5-b585-4f5e-928d-883186fde411)

A pasta `features` conterá todas as características de nosso sistema (atualmente, temos apenas a *feature* **AUTH**).

Dentro de cada feature, temos:

* Domain - Tudo o que é de domínio da aplicação, ou seja, regras de negócio, entidades, etc. Estas partes não tem conhecimento algum de nada (além de contratos), não geram E/S (ou seja, não criam registros em bancos de dados, não chamam serviços remotos, etc., tudo sendo implementado através de contratos para que estas E/S sejam testáveis e não gerem *side-effects* (efeitos colaterais - alterar o estado físico de uma aplicação por uma escrita em banco de dados, de uma chamada a um serviço web, etc.). Neste exemplo, temos duas entidades: `AuthServiceCredential` que contém o resultado de uma autenticação OAuth (contendo dados do usuário, access token e id token) e `Principal`, que representa um usuário autenticado. Temos uma notificação `SignInAuthStageNotification` que emitirá o estado atual de uma autenticação (i.e.: aguardando google, aguardando firebase, aguardando banco de dados local, etc.). Além disso, temos duas *features* iniciais: `SignIn` e `SignOut`.
* Infrastructure - Todos os contratos de serviços que deverão ser implementados. Aqui temos contratos para o serviço de OAuth (a autenticação via Google ou Apple), o serviço de autenticação (Firebase Auth) e nosso repositório para guardar informações (banco de dados para registar os logins). Não há uma regra definida se tais contratos sejam interfaces (`abstract interface class`) ou classes abstratas (`abstract base class`). Interfaces apenas dizem que tais métodos ou campos devem ser implementados. Possui apenas a assinatura de tais métodos e absolutamente nenhum outro código (nem mesmo construtores). Há casos, porém, que certas funcionalidades são padrão para qualquer implementação (por exemplo, se implementássemos autenticação via e-mail, seria interessante validar tal e-mail, logo, poderíamos ter um contrato de autenticação base (`BaseAuthService`) que implementaria esta validação e então chamaria um método abstrato (método sem código, somente assinatura, exatamente como interfaces). O princípio D.R.Y. é mais importante do que regras neste ponto.
* Presentation - Aqui fica tudo o que é de domínio do Flutter: componentes específicos para login (como widgets que desenham o logotipo do Google ou Apple para adicionar em botões), a página de autenticação em si, etc.
* Settings: Como os packages escolhidos tem configurações, criamos uma classe que mantém tais configurações para serem acessadas.
* States: Finalmente, um gerenciador de estado que mantém o usuário atual ou `null` caso nenhum usuário esteja autenticado.

Adicionalmente, temos uma feature mais genérica para monitoramento de erros e performance, através dos pipeline behaviors.

Na pasta `infrastructure` que fica fora de `features` temos a implementação de fato dos contratos que precisamos (que são implementação de login com `google_sign_in`, `sign_in_with_apple` e `firebase_auth`, além do nosso repositório de registro de logins com o package `isar`). 

Tudo o que está sob `features` pode ser seguramente copiada e colada em outros projetos.

Tudo o que está sob `infrastructure` pode ser copiada e colada, se a implementação for a mesma (ou seja, se outros projetos também utilizarem Firebase Auth, etc.).

## Inicialização

A inicialização do app ficará assim:

```dart
Future<void> main() async {
  _registerSettings();
  _registerServices();
  _registerStates();
  _registerHandlers();
  _registerPipelines();
  await $initializeAsync();
  runApp(const App());
}

void _registerSettings() {
  $settings.add(
    AuthSettings(
      googleClientId: DefaultFirebaseOptions.ios.androidClientId!,
      appleServiceId: "TODO:",
      appleRedirectUri: Uri.parse("https://somewhere"),
      isGame: true,
    ),
  );
}

void _registerServices() {
  $services.registerBootableSingleton(
    (get) => const FirebaseApp(),
  );

  $services.registerTransient<IAuthService>(
    (get) => const FirebaseAuthService(),
  );

  $services.registerTransient<IAuthRepository>(
    (get) => const IsarAuthRepository(),
  );

  $services.registerTransient<IGoogleOAuthService>(
    (get) => GoogleSignInService(authSettings: get<AuthSettings>()),
  );

  $services.registerTransient<IAppleOAuthService>(
    (get) => AppleSignInService(authSettings: get<AuthSettings>()),
  );
}

void _registerStates() {
  $states.registerState(
    (get) => AuthState(authService: get<IAuthService>()),
  );
}

void _registerHandlers() {
  $mediator.registerRequestHandler(
    (get) => SignInRequestHandler(
      authService: get<IAuthService>(),
      googleOAuthService: get<IGoogleOAuthService>(),
      appleOAuthService: get<IAppleOAuthService>(),
      authRepository: get<IAuthRepository>(),
    ),
  );

  $mediator.registerRequestHandler(
    (get) => SignOutRequestHandler(
      authService: get<IAuthService>(),
      googleOAuthService: get<IGoogleOAuthService>(),
      appleOAuthService: get<IAppleOAuthService>(),
      authRepository: get<IAuthRepository>(),
    ),
  );
}

void _registerPipelines() {
  $mediator.registerPipelineBehavior(
    0,
    (get) => const ErrorMonitoringPipelineBehavior(),
    registerAsTransient: false,
  );

  $mediator.registerPipelineBehavior(
    1000,
    (get) => const PerformancePipelineBehavior(),
  );
}
```

Este código adiciona as configurações de autenticação que são específicas de cada projeto (o GoogleClientId é obtido do arquivo gerado pelo Firebase CLI, o AppleServiceId é obtido das configurações geradas no site que configuramos o login via Apple (developer.apple.com) e o AppleRedirectUri especifica a Uri que a autenticação OAuth usa para completar a autenticação.

Depois, os serviços são registrados:

* Há um serviço especial chamado `FirebaseApp` registrado como `IBootable` que serve somente para iniciar o Firebase (todos os packages do Firebase precisam desta inicialização, então adicioná-la como um `IBootable` faz com que ela seja inicializada logo no início, antes de qualquer outro serviço ser chamado).
* Registramos nossas implementações atreladas a cada contrato necessário, ou seja, toda vez que precisarmos de um `IAuthService`, um `FirebaseAuthService` será retornado. Note que alguns serviços podem requerer outras classes registradas, como, por exemplo, devemos passar um `AuthSettings` para o `GoogleSignInService`. Ao fazermos isso via injeção de dependência, garantimos a definição de tais valores em apenas um lugar.
* Registramos então nosso gerenciador de estado para autenticação, o `AuthState`
* Para cada *feature*, existe uma mensagem (`SignInRequest` e `SignOutRequest`). Estas mensagens são recebidas e implementadas por um *handler*, que é uma classe de pura regra de negócio que irá orquestrar (ou aplicar uma receita de bolo) exatamente como se faz um *sign in* ou um *sign out*. Para isso, registramos dois `RequestHandlers`, um para cada mensagem.
* Finalmente, registramos dois pipeline behaviors para enviar todas exceções não tratadas ao Firebase Crashlytics e um para medir quanto tempo cada *request* leva para ser concluído.

## Sign In

Este é o código completo da *feature* *sign in*:

```dart
@MappableEnum()
enum SignInFailure {
  unknown,
  cancelledByUser,
  userDisabled,
  networkRequestFailed,
  notSupported,
}

typedef SignInResponse = Response<Principal?, SignInFailure>;

final class SignInRequest implements IRequest<SignInResponse> {
  const SignInRequest(this.authProvider);

  final AuthProvider authProvider;
}

final class SignInRequestHandler
    implements IRequestHandler<SignInResponse, SignInRequest> {
  const SignInRequestHandler({
    required IAuthService authService,
    required IGoogleOAuthService googleOAuthService,
    required IAppleOAuthService appleOAuthService,
    required IAuthRepository authRepository,
  })  : _authService = authService,
        _googleOAuthService = googleOAuthService,
        _appleOAuthService = appleOAuthService,
        _authRepository = authRepository;

  final IAuthService _authService;
  final IGoogleOAuthService _googleOAuthService;
  final IAppleOAuthService _appleOAuthService;
  final IAuthRepository _authRepository;

  static const _logger = Logger<SignInRequestHandler>();

  @override
  Future<SignInResponse> handle(SignInRequest request) async {
    final IOAuthService oAuthService =
        request.authProvider == AuthProvider.apple
            ? _appleOAuthService
            : _googleOAuthService;

    $mediator.publish(
      SignInAuthStageNotification(
        request.authProvider == AuthProvider.apple
            ? AuthStage.signingInWithApple
            : AuthStage.signingInWithGoogle,
      ),
    );

    _logger.info("Signing in with ${request.authProvider}");

    final oAuthResponse = await oAuthService.signIn();

    if (oAuthResponse.isFailure) {
      const SignInAuthStageNotification(AuthStage.idle);
      return SignInResponse.fromFailure(oAuthResponse);
    }

    $mediator.publish(
      const SignInAuthStageNotification(AuthStage.authorizing),
    );

    _logger.info("Authorizing");

    final authResponse = await _authService.signIn(oAuthResponse.value);

    if (authResponse.isFailure) {
      const SignInAuthStageNotification(AuthStage.idle);
      return authResponse;
    }

    $mediator.publish(
      const SignInAuthStageNotification(AuthStage.registering),
    );

    _logger.info("Persisting");

    final repoResponse = await _authRepository.signIn(authResponse.value!);

    if (repoResponse.isFailure) {
      const SignInAuthStageNotification(AuthStage.idle);
      return repoResponse;
    }

    $mediator.publish(
      const SignInAuthStageNotification(AuthStage.idle),
    );

    Future<void>.delayed(const Duration(milliseconds: 500))
        .then(
          (_) => $mediator.publish(
            const SignInAuthStageNotification(AuthStage.idle),
          ),
        )
        .ignore();

    if (repoResponse.isSuccess) {
      $states.get<AuthState>().change(repoResponse.value);
    }

    return repoResponse;
  }
}
```

Primeiro, implementamos igualdade por valor a eventos, requests, entidades, etc. usando a ótima biblioteca `dart_mappable`. Isso é necessário para evitar rebuilds em nossa interface ou disparo de serviços quando nada mudou. Dart faz uma comparação por referência, ou seja, um objeto somente é igual ao outro se eles apontarem para o mesmo objeto na memória. Quando utilizamos imutabilidade, sempre geramos uma cópia de um objeto, com possíveis alterações. Esta cópia, para o Dart, sempre é diferente da primeira (mesmo que os valores sejam os mesmos). `dart_mappable` então implementa comparação via valor (ou seja, compara cada campo dentro de uma classe para verificar se elas representam exatamente a mesma entidade). Usamos `dart_mappable` porque ele não influencia o que você pode fazer com sua classe (`freezed` por exemplo impede ou dificulta certos recursos como herança, generics, métodos, etc.) e também implementa diversos outros recursos úteis, como `copyWith` e serialização (`toMap` e `toJson`).

Usando os princípios descritos na Vertical Slice Architecture (https://www.jimmybogard.com/vertical-slice-architecture/), tentamos manter tudo relativo a uma *feature* dentro de um mesmo arquivo (somente separando implementações que não podem ser copiadas e coladas seguramente para outros projetos ou entidades que geralmente são utilizadas sem que se precise de todo o resto). Então nosso arquivo contém: 

1) Um enum `SignInFailure` que representa os possíveis erros que podem acontecer durante um sign in.
2) Um `Request` que representa o desejo de fazer um sign in (a UI irá disparar este Request, informando se deseja autenticar via Google ou Apple, e tudo será feito "automaticamente").
3) Um handler desta request, que irá implementar a lógica de sign in per se. Esta lógica emite eventos do tipo `SignInAuthStageNotification` para que a UI possa mostrar o que está acontecendo e então tenta se autenticar com o provedor especificado (Google ou Apple), que emitirão um erro ou uma credencial (contendo dados do usuário e tokens de acesso). No caso de sucesso, isso será enviado ao Firebase Auth para gerar um usuário autenticado de fato. Finalmente, enviamos este usuário quase pronto para o repositório, para que possamos escrever no banco de dados informações sobre o usuário e sobre o login feito.

Note que algumas coisas ainda estão faltando, como reportar este login ao Firebase Analytics, corrigir o fato do sign in com a Apple só enviar o nome do usuário na primeira autenticação (nossa lógica deve considerar esta limitação do provedor e ajustar o usuário autenticado de acordo, como uma regra de negócio).

Mas, basicamente, temos aqui todos os requisitos que definimos, como reusabilidade, granularidade de *features*, testabilidade, etc. e podemos adicionar ou remover características de forma bem simples sem nem precisar mais alterar as partes que já estejam prontas. Por exemplo, para implementar o registro do login no Firebase Analytics, simplesmente podemos escrever um serviço `IBootable` que se registra como um `listener` do estado da autenticação (`AuthState`) e, quando esta ocorre, faz o que tem que fazer (que é, basicamente, chamar um método dizendo que o usuário com ID *X* se autenticou). Podemos, adicionalmente, emitir um evento específico no final do procesos de autenticação (como um `UserHasSignedIn(Principal)`), assim, qualquer módulo que venha a ser escrito no futuro poderá escutar este evento e fazer o que desejar, sem que o restante da aplicação tenha este conhecimento. 

As possibilidades e liberdades de implementação são abertas.

### Implementações

Alguns detalhes extras nas implementações ou uso:

`google_sign_in_service`

```dart
final class GoogleSignInService implements IGoogleOAuthService {
  const GoogleSignInService({
    required AuthSettings authSettings,
  }) : _authSettings = authSettings;

  final AuthSettings _authSettings;

  static GoogleSignIn? __googleSignIn;

  GoogleSignIn get _googleSignIn => __googleSignIn ??= GoogleSignIn(
        clientId: kIsWeb || Platform.isAndroid == false
            ? _authSettings.googleClientId
            : null,
        hostedDomain: kIsWeb || Platform.isAndroid == false
            ? _authSettings.googleClientUrl
            : null,
        scopes: ["email"],
        signInOption:
            _authSettings.isGame ? SignInOption.games : SignInOption.standard,
      );

  @override
  Future<AuthServiceCredentialResponse> signIn() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        return const AuthServiceCredentialResponse.failure(
          SignInFailure.cancelledByUser,
        );
      }

      final auth = await account.authentication;

      return AuthServiceCredentialResponse.success(
        AuthServiceCredential(
          accessToken: auth.accessToken ?? "",
          idToken: auth.idToken ?? "",
          userName: account.displayName,
          userEmail: account.email,
          userAvatarUrl: account.photoUrl,
          authProvider: AuthProvider.google,
        ),
      );
    } catch (ex, stackTrace) {
      return AuthServiceCredentialResponse.failure(
        SignInFailure.unknown,
        ex,
        stackTrace,
      );
    }
  }

  @override
  Future<SignOutResponse> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }

    return const SignOutResponse.success(null);
  }
}
```

`firebase_auth_service.dart`:

```dart
final class FirebaseAuthService implements IAuthService {
  const FirebaseAuthService();

  static const _logger = Logger<FirebaseAuthService>();

  @override
  Future<SignInResponse> getCurrentPrincipal() async {
    final cu = FirebaseAuth.instance.currentUser;

    if (cu == null) {
      _logger.debug(() => "No user authenticated");
      return const SignInResponse.success(null);
    }

    AuthProvider? authProvider;

    for (final data in cu.providerData) {
      if (data.providerId == AppleAuthProvider.PROVIDER_ID) {
        authProvider = AuthProvider.apple;
        break;
      }

      if (data.providerId == GoogleAuthProvider.PROVIDER_ID) {
        authProvider = AuthProvider.google;
        break;
      }
    }

    assert(authProvider != null, "AuthProvider should have a value");

    final principal = Principal.normalize(
      id: cu.uid,
      name: cu.displayName,
      avatarUrl: cu.photoURL,
      email: cu.email,
      authProvider: authProvider!,
    );

    _logger.debug(() => "Authenticated user: ${principal}");

    return SignInResponse.success(principal);
  }

  @override
  Future<SignInResponse> signIn(
    AuthServiceCredential authServiceCredential,
  ) async {
    try {
      final credential =
          authServiceCredential.authProvider == AuthProvider.apple
              ? AppleAuthProvider.credential(
                  authServiceCredential.accessToken,
                )
              : GoogleAuthProvider.credential(
                  accessToken: authServiceCredential.accessToken,
                  idToken: authServiceCredential.idToken,
                );

      final auth = await FirebaseAuth.instance.signInWithCredential(credential);

      if (auth.user == null) {
        _logger.error(
          "auth.user should not be null after signInWithCredential!",
        );

        return const SignInResponse.failure(SignInFailure.cancelledByUser);
      }

      return getCurrentPrincipal();
    } on FirebaseAuthException catch (ex, stackTrace) {
      switch (ex.code) {
        case "user-disabled":
          return SignInResponse.failure(
            SignInFailure.userDisabled,
            ex,
            stackTrace,
          );
        case "network-request-failed":
          return SignInResponse.failure(
            SignInFailure.networkRequestFailed,
            ex,
            stackTrace,
          );
        default:
          return SignInResponse.failure(
            SignInFailure.unknown,
            ex,
            stackTrace,
          );
      }
    }
  }

  @override
  Future<SignOutResponse> signOut() async {
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }

    return const SignOutResponse.success(null);
  }
}
```

`login_page`:
```dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _signIn(BuildContext context, AuthProvider authProvider) async {
    final response = await $mediator.send(SignInRequest(authProvider));

    if (response.isSuccess) {
      return;
    }

    switch (response.failure) {
      case SignInFailure.cancelledByUser:
        break;
      case SignInFailure.networkRequestFailed:
        await context.showOKDialog(
          title: "No internet connection",
          message: "There were a failure while trying to reach the "
              "authentication service.\n\nPlease, check your internet connection.",
        );
      case SignInFailure.userDisabled:
        await context.showOKDialog(
          title: "User is disabled",
          message: "Your user is disabled, please, contact support.",
        );
      default:
        await context.showOKDialog(
          title: "Oops",
          message: "An unknown error has ocurred!\n\n"
              "(Details: ${response.exception})",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: $mediator.getChannel<SignInAuthStageNotification>(),
      initialData: const SignInAuthStageNotification(AuthStage.idle),
      builder: (context, snapshot) {
        final currentAuthStage = snapshot.data?.stage ?? AuthStage.idle;

        final authMessage = switch (currentAuthStage) {
          AuthStage.idle => "Sign in with",
          AuthStage.signingInWithApple => "Awaiting Apple...",
          AuthStage.signingInWithGoogle => "Awaiting Google...",
          AuthStage.authorizing => "Authorizing...",
          AuthStage.registering => "Registering...",
        };

        final isBusy = currentAuthStage != AuthStage.idle;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  const AppLogo(dimension: 200),
                  const SizedBox.square(dimension: 16),
                  Text(
                    "App Name",
                    style: theme.textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  Text(
                    authMessage,
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox.square(dimension: 8),
                  isBusy
                      ? const Center(
                          child: SizedBox.square(
                            dimension: 48,
                            child: Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _AuthProviderButton(
                              onPressed: () =>
                                  _signIn(context, AuthProvider.google),
                              icon: const GoogleLogo(dimension: 16),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -2),
                              child: Text(
                                " or ",
                                style: theme.textTheme.labelMedium,
                              ),
                            ),
                            _AuthProviderButton(
                              onPressed: () =>
                                  _signIn(context, AuthProvider.apple),
                              icon: const AppleLogo(
                                dimension: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: isBusy ? null : () {},
                          child: Text(
                            "PRIVACY POLICY",
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        TextButton(
                          onPressed: isBusy ? null : () {},
                          child: Text(
                            "ABOUT",
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        TextButton(
                          onPressed: isBusy ? null : () {},
                          child: Text(
                            "TERMS OF USE",
                            style: theme.textTheme.labelSmall,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _AuthProviderButton extends StatelessWidget {
  const _AuthProviderButton({
    required this.onPressed,
    required this.icon,
  });

  final void Function() onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      isSelected: true,
      icon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
            )
          ],
        ),
        child: icon,
      ),
    );
  }
}
```
