# FATE em português brasileiro

Tradução comunitária dos **textos do FATE clássico**, para Windows. Projeto independente, sem vínculo com WildTangent, Steam ou GOG.

**Versão: 1.0.0-rc.1 — candidata a lançamento, em validação.**

## Baixar e instalar

Baixe o pacote ZIP em [Releases](https://github.com/wlissesxz-code/fate-pt-br/releases). Se ainda não houver um pacote publicado, use **Code → Download ZIP** e extraia a pasta inteira.

1. Tenha o FATE clássico instalado e com os arquivos originais em **inglês**.
2. Feche o jogo e extraia o ZIP para uma pasta gravável, fora da instalação do jogo.
3. Execute **Validar.cmd** para conferir a compatibilidade sem alterar os arquivos do jogo.
4. Execute **Instalar.cmd**. O instalador procura instalações Steam/GOG; se não encontrar, pede a pasta que contém `fate.exe`.
5. Mantenha o idioma do jogo em inglês e abra-o normalmente pela sua loja.

Não copie DLLs de outra edição por cima das suas. O instalador usa a biblioteca de idioma da sua própria instalação e aplica apenas os recursos traduzidos.

### Compatibilidade e estado dos testes

| Edição | Detecção | Estado |
|---|---|---|
| GOG, FATE clássico | Registro do Windows ou escolha de pasta | Base local 1.39 usada nos testes automatizados. A tradução anterior foi testada em jogo; esta distribuição ainda requer confirmação em jogo. |
| Steam, FATE clássico, app **246840** | Registro, `libraryfolders.vdf` e `appmanifest_246840.acf`, incluindo bibliotecas em outros discos | Suporte implementado por validação dos arquivos. **Ainda não testado com arquivos reais da Steam.** |
| FATE: Reawakened, expansões e outros jogos da série | Não suportados | Este pacote é exclusivo do FATE clássico. |

Arquivos de versão desconhecida ou modificados são recusados **antes da instalação**. A validação por contexto pode aceitar diferenças de cabeçalho e posição dos textos, mas não ignora divergências nas regras ou nas referências usadas pela tradução. A detecção da loja, sozinha, não prova compatibilidade com seus arquivos.

## O que está traduzido

- Interface, menus, atributos, habilidades e efeitos de equipamentos.
- Nomes e descrições de itens e magias.
- Criaturas, personagens, falas escritas de comerciantes e serviços.
- Missões, dicas e partes descritivas dos nomes gerados.
- Referências entre os nomes da cidade, invocações, transformações e equipamentos.

Nomes próprios e termos de fantasia permanecem quando apropriado. O áudio original, o manual e os termos legais do jogo não fazem parte da tradução. O teste experimental de voz do menestrel e os ajustes pessoais de resolução não integram esta distribuição.

## Backup e desinstalação

Antes de substituir qualquer arquivo, o instalador prepara e valida toda a tradução, cria backup e confere as cópias. Em caso de erro na gravação, tenta restaurar automaticamente os arquivos anteriores.

O backup e o registro da instalação ficam em **`.fate-ptbr`**, dentro da pasta do jogo. Não apague essa pasta enquanto a tradução estiver instalada.

Para remover a tradução, feche o FATE e execute **Desinstalar.cmd**. A restauração confere os hashes dos backups e recusa sobrescrever arquivos que tenham sido modificados por outra tradução ou atualização da loja.

### Já usava os pacotes anteriores deste projeto?

Restaure-os com o `Restaurar.cmd` do backup correspondente antes de usar este instalador. Se usou o teste de voz, restaure esse teste também. Este pacote espera os arquivos originais em inglês e não migra automaticamente instalações antigas sem registro de backup.

### A Steam ou GOG atualizou/verificou os arquivos?

Sempre que possível, remova a tradução **antes** de atualizar ou verificar os arquivos da loja. Se a atualização já ocorreu e a restauração foi recusada, não force a cópia de DLLs antigas. Restaure os arquivos pela loja e faça novamente a validação em inglês. Consulte [suporte e testes](docs/COMPATIBILIDADE.md).

## Saves e teste em jogo

O instalador não altera os saves. Contudo, saves antigos podem conter nomes gravados na língua anterior; isso não equivale a compatibilidade de saves confirmada. Faça uma cópia dos seus saves e teste primeiro com um personagem novo.

A confirmação visual continua necessária em diferentes resoluções, especialmente nas caixas de diálogo, nomes gerados, recompensas e serviços da cidade.

## Uso por linha de comando

```powershell
.\Instalar.ps1 -GamePath 'C:\Games\FATE' -ValidateOnly
.\Instalar.ps1 -GamePath 'C:\Games\FATE'
.\Desinstalar.ps1 -GamePath 'C:\Games\FATE'
```

O caminho é um exemplo; não existe pasta de instalação fixa no código. Os arquivos `.cmd` usam o Windows PowerShell já instalado e não alteram permanentemente a política de execução do sistema.

## Desenvolvimento e distribuição

O repositório contém textos e planos de aplicação, **sem executáveis, DLLs, cenas completas, áudios ou saves do jogo**. As cenas são ajustadas localmente somente nos nomes dos personagens. As bibliotecas de idioma são reconstruídas localmente a partir da cópia do jogador, preservando os demais recursos e o código da edição instalada.

```powershell
powershell -NoProfile -File .\tests\Test-Payload.ps1
powershell -NoProfile -File .\tests\Test-Install.ps1 -OriginalGamePath 'C:\Games\FATE-original'
powershell -NoProfile -File .\scripts\Build-Release.ps1
```

O teste de integração exige arquivos originais fornecidos localmente pelo responsável pelo teste. Eles nunca são incluídos no GitHub. Os testes com variações de pasta e cabeçalhos não são apresentados como testes de uma edição Steam real.

Veja [CONTRIBUTING.md](CONTRIBUTING.md), [CHANGELOG.md](CHANGELOG.md) e [a matriz de testes](docs/COMPATIBILIDADE.md).

Os direitos sobre o jogo e suas marcas pertencem aos respectivos titulares. A publicação deste projeto não concede direitos sobre os arquivos originais. A licença de reutilização do código e dos textos da tradução ainda não foi definida; para incorporar o material em outro projeto, consulte o mantenedor.
