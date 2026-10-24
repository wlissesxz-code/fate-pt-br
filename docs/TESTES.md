# Resultado dos testes — 1.0.0-rc.1

Base usada: arquivos locais em inglês da edição GOG 1.39. Nenhum arquivo original do jogo faz parte do repositório.

| Verificação | Resultado |
|---|---|
| 1040 recursos traduzidos, variáveis e 45 planos DAT | Passou |
| Recusa de caminhos fora da pasta do jogo | Passou |
| Aplicação por contexto após cabeçalho adicional | Passou |
| Recusa de contexto incompatível | Passou |
| Busca de biblioteca Steam adicional com caminho contendo espaços (simulada) | Passou |
| Validação sem alterar os arquivos do jogo | Passou |
| Instalação com todos os idiomas ingleses: 53 arquivos | Passou |
| Instalação somente com inglês americano: 35 arquivos | Passou |
| Código e demais seções das DLLs preservados fora de .rsrc | Passou |
| Segunda execução da instalação sem duplicar alterações | Passou |
| Recusa de restauração após modificação externa | Passou |
| Desinstalação e conferência byte a byte dos originais | Passou |
| Recusa de arquivo desconhecido antes de modificar outras partes | Passou |

Esses testes foram executados no Windows PowerShell. O teste de integração usa cópias de arquivos GOG; a variante com outra estrutura de pastas não é uma edição Steam real.

**Pendente:** validar e jogar na edição Steam real; testar esta distribuição no jogo; verificar várias resoluções, todos os nomes gerados e saves antigos.
