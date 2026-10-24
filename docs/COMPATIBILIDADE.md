# Compatibilidade e testes

## Escopo

Windows, FATE clássico, jogo em inglês. Steam app 246840 e GOG game 2050639399 são usados somente para localizar a pasta; o executável, a integração da loja e o DRM não são modificados.

## Validação

- Planos DAT usam hashes normalizados e, quando o hash difere, âncoras de texto de ambos os lados da alteração.
- Referências de nomes, magias, armas preferidas e transformações são aplicadas junto com as definições traduzidas.
- Arquivos de regras são preservados fora dos campos de tradução previstos.
- Cenas são lidas em Windows-1252 e alteradas somente nos valores `NAME=` previstos.
- DLLs são abertas como dados, sem executar seu código. O conteúdo original de cada recurso é conferido antes da alteração e a tradução é relida após a gravação.
- Entradas britânicas diferentes são aceitas explicitamente. O erro original `#2` no recurso 824 é corrigido para `$2`.
- Localizações inglesas opcionais ausentes são ignoradas; a edição americana e os arquivos principais são exigidos.

## Testes automatizados

`Test-Payload.ps1` não precisa do jogo: verifica IDs, parâmetros, ordem das operações, caminhos e recusa de versões incompatíveis no aplicador. Também impede a inclusão de binários e áudios no pacote.

`Test-Install.ps1` usa uma cópia temporária de arquivos originais fornecidos pelo responsável e verifica:

1. Validação sem alterar os arquivos do jogo.
2. Instalação completa com backup.
3. Reexecução idempotente.
4. Recusa de desinstalação após alteração externa.
5. Restauração byte a byte.
6. Recusa de arquivo incompatível antes de modificar outra parte do jogo.
7. Pastas com as duas variantes inglesas e somente a americana; cabeçalho adicional para exercitar as âncoras.

Essas variações usam a base disponível ao responsável. Elas não substituem um teste real de outra distribuição.

## O que precisamos confirmar na Steam

Execute `Validar.cmd` em uma cópia original e depois, se a validação passar, teste menu, personagem novo, cidade, masmorra, comerciantes, magias, peixes e companheiro. Registre a versão do jogo e os idiomas presentes. Remova a tradução e confirme que o jogo original volta a funcionar.

Não envie o jogo inteiro, DLLs ou saves com dados pessoais em uma issue. Informe o nome do arquivo/recurso que foi recusado, a edição e uma captura da mensagem.

## Instalações antigas ou modificadas

O instalador novo não substitui às cegas os pacotes antigos. Restaure os respectivos backups ou obtenha os arquivos originais pela loja. A recusa de um arquivo desconhecido é intencional: evita aplicar uma referência traduzida sem traduzir a definição correspondente.

A tradução não altera configuração de vídeo, vozes, saves ou teclado. Nomes guardados em saves antigos e concordância dos afixos continuam exigindo inspeção em jogo.
