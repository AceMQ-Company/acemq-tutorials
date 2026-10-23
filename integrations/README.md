# Step 8: in your framework

The examples step 8 runs, one per framework integration. Each is the step 1
program — three orders published with a confirm and consumed — written the way
that framework writes it, and each exits non-zero unless all three came back.

| Directory | Framework | Integration |
|---|---|---|
| [`spring-boot`](spring-boot) | Spring Boot 3 | [acemq-java-amqp-spring-boot-starter](https://acemq.org/acemq-java-amqp-spring-boot-starter/) |
| [`hosting-csharp`](hosting-csharp), [`hosting-vbnet`](hosting-vbnet) | .NET Generic Host | [acemq-dotnet-amqp-hosting](https://acemq.org/acemq-dotnet-amqp-hosting/) |
| [`fastapi`](fastapi) | FastAPI | [acemq-python-amqp-fastapi](https://acemq.org/acemq-python-amqp-fastapi/) |
| [`rails`](rails) | Rails | [acemq-ruby-amqp-rails](https://acemq.org/acemq-ruby-amqp-rails/) |

Go has no framework integration, so it has no step 8.

They live here rather than in an examples repository because the integrations
have none. The images build them with the versions in [`../pins.env`](../pins.env):
`<LANG>_INTEGRATION_VERSION` for the integration and `<LANG>_VERSION` for the
library under it. `Directory.Build.props`, `nuget.config` and
`hosting-appsettings.json` here are the two .NET projects' shared settings.

To run one outside an image, start a broker
(`docker compose up -d --wait broker` at the repository root) and then:

```bash
(cd spring-boot && mvn -q package dependency:copy-dependencies -DincludeScope=runtime \
   && java -cp "target/classes:target/dependency/*" org.acemq.tutorials.OrdersApplication)
dotnet run --project hosting-csharp          # or hosting-vbnet
(cd fastapi && pip install -r requirements.txt && python main.py)
(cd rails && bundle install && bundle exec ruby main.rb)
```
