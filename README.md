# Lovely
Uma pequena e poderosa biblioteca que estende a linguagem Lua com novos recursos como classes, switches e mais

# Configuração rápida

1. [Baixe a última versão do `Lovely` (a API é estável :), relaxa)](https://github.com/natanael-b/Lovely2/releases/download/continuous/Lovely.lua)
2. Coloque no seu projeto (use linkagem estática, evita dor de cabeça)
3. Coloque isso no início do arquivo principal (isso faz ele modificar todos os `require` abaixo automaticamente assim vc só precisa chamar o Lovely uma vez)
```lua
require "Lovely"
```

## Core (pseudo-instruções)

### `class`

Essa declaração permite declarar classes em Lua com uma sintaxe similar a outras linguagens como Javascript:

```lua
class "Name" {
  -- Metódos e propriedades aqui
  -- também suporta metamétodos
}
```

Também suporta herança:

```lua
class "Name" (ClasseBase) {
  -- Métodos e propriedades aqui
  -- também suporta metamétodos
}
```

Exemplo:

```lua
class "Retangulo" {
  cor = "vermelho";
  
  -- Opcionalmente pode se usar uma função contructor
  -- Essa função é chamada uma vez quando a classe é instanciada
  constructor = function (self,largura,altura)
                  self.largura = largura or 800
                  self.altura = altura or 600
                end;

  -- O primeiro parâmetro (self) faz referência a instância do objeto
  area = function (self)
           print(self.largura*self.altura)
         end
}

----------------------------------------------------

teste = Retangulo:new(920,480)
teste.largura = 640

teste:area() -- 307200

```

### `new`

Uma _syntax sugar_ para tornar o instanciamento de classes mais familiar:

```lua
teste = new "Retangulo"
-- Ambas as declarações são equivalentes
teste = Retangulo:new()
```

### `with`
Essa declaração permite deixar o código mais legível ao chamar sucessivamente métodos e propriedades de um objeto:

```lua
teste = new "Exemplo"
-- Com with:
with (teste) {
  propriedade_1 = "valor 1";
  propriedade_2 = "valor 2";
  propriedade_3 = "valor 3";
  metodo_1 = {};
  metodo_2 = {"parâmetro 1","parâmetro"};
  metodo_3 = {{"parâmetro 1","parâmetro"}};
}
-- Sem o with:
teste.propriedade_1 = "valor 1"
teste.propriedade_2 = "valor 2"
teste.propriedade_3 = "valor 3"
teste:metodo_1()
teste:metodo_2("parâmetro 1","parâmetro")
teste:metodo_3({"parâmetro 1","parâmetro"})

```

> Note que os argumentos dos métodos são passados através de uma `table`

Outro detalhe relevante é que o `with` retorna o objeto passado permitindo seu uso com objetos imutáveis como o tipo `string`:

```lua
teste = "exemplo"
teste = with (teste) {
          upper = {};
          sub = {1,2};
        } -- EX
```

### `type`

Lovely adiciona suporte a tipos customizados através de uma manipulação da função `type`

```lua
teste = new "Retangulo"

type(teste) -- Retangulo
```

### `readonly`

Lovely possui mecanismos para criar tabelas somente-leitura de forma simplificada:

```lua
teste = readonly {"a","b","c"}
teste[1] = 42 -- Causa um erro por tentativa de modificar uma tabela somente leitura
type(teste) -- table:ro
```

### `literal`

Essa função adiciona um `%` antes dos caracteres especiais Lua, permitindo usar uma `string` sem alteração aos métodos `gsub`, `match`, `gmatch`, `find` e/ou qualquer outro método que use padrões de `string`

```lua
literal "(00) 91234-5678" -- %(00%) 91234%-5678
```

### `charset`

Essa declaração retorna todos os caracteres pertencentes a uma ou mais classes de caracteres:

```lua
charset "d" -- 0 1 2 3 4 5 6 7 8 9
```

Tabela com as classes de caractere e os valores:

|Classe|Caracteres|
|------|----------|
| **`.`** | Representa todos os caracteres ASCII |
| **`a`** | Representa todas as letras (não inclui letras com acento) |
| **`c`** | Representa todos os caracteres de controle |
| **`d`** | Representa todos os dígitos |
| **`g`** | Representa todos os caracteres gráficos exceto espaço |
| **`l`** | Representa todas as letras minúsculas (não inclui letras com acento) |
| **`u`** | Representa todas as letras maiúsculas (não inclui letras com acento) |
| **`p`** | Representa todas as pontuações gráficas |
| **`s`** | Representa todos os caracteres de espaço em branco |
| **`w`** | Combinação de `a`e `d` |
| **`x`** | Todos os caracteres hexadecimais [0-9,a-f e A-F] |

> **Nota:** o retorno não será uma tabela, mas sim valores individuais

### `switch`

Lovely provê um substituto para a declaração `if-elseif-else` chamada `switch`

```lua
switch (valor) {
  ["1"]  = "valor1"; 
  ["2"]  = "valor2";
  ["3"]  = "valor3";
  [456]  = "Exemplo chave numérica";
  [true] = "Exemplo chave booleana";
  ["4"]  = function ()
             return "Retornado de uma função"
           end;
  ["5"]  = {};
  [789]  = false;
  ["6"]  = 963;
  
  default = "valor padrão";
}
```

A declaração `switch` busca pelo `valor` passado na tabela se a chave existir  o valor é retornado, caso seja uma função a função é executada e o valor retornado pela função é retornado pelo `switch`, caso não seja encontrada nenhuma chave, o valor na chave `default` é retornado.

### `const`

Essa declaração permite que constantes globais sejam declaradas em Lua fazendo o script falhar caso o valor de uma variável seja alterado:

```lua
const {
  NOME="valor"
}

NOME = 123 -- Retorna um erro
```

## Core (funções auxiliares)

### `wrap`

Essa função permite sobrescrever uma função sem perder acesso a função original, é usada por exemplo, para implementar o suporte a tipos customizados:

```lua
nome = wrap(nome, function (self,argumento_1,argumento_2)
                    -- A função original fica armazenada no campo original_function
                    -- no parametro self:
                    local resultado = self.original_function(argumento_1)
                  end)
```

### `is`

Essa função verifica se uma tabela contém pelo menos um elemento igual ao elemento passado como referência, retornando `true` e a posição do primeiro item igual se a tabela contiver e `false` se a tabela não contiver o item:

```lua
is(5,{7,9,6,5,7,5}) -- true 4
is(2,{7,9,6,5,7,1}) -- false
```

Opcionalmente é possível passar uma função para transformar os elementos antes de verificar, note que os elementos da tabela somente são afetados na verificação, em caso verdadeiro a posição sempre será 1:

```lua
is("number",{"b","a","y"},function (v) return type(tonumber(v)) end) -- false
is("number",{7,9,"6",5,7},function (v) return type(tonumber(v)) end) -- true 1
```

### `none`

Essa função verifica se todos os elementos de uma tabela são diferentes do elemento passado como referência, retornando `true` se todos forem diferentes e `false` e a posição do primeiro item igual:

```lua
none(5,{7,9,6,5,7,5}) -- false 4
none(2,{7,9,6,5,7,1}) -- true
```

Opcionalmente é possível passar uma função para transformar os elementos antes de verificar, note que os elementos da tabela somente são afetados na verificação, caso seja falso a posição sempre será 1:

```lua
none("number",{"b","a","y"},function (v) return type(tonumber(v)) end) -- true
none("number",{7,9,"6",5,7},function (v) return type(tonumber(v)) end) -- false 1
```


### `all`

Essa função verifica se todos os elementos de uma tabela são iguais ao elemento passado como referência, retornando `true` se todos forem iguais e `false` e a posição do primeiro item diferente:

```lua
all(5,{5,5,5,5,5,5,5}) -- true
all(2,{2,2,2,2,3,2,2}) -- false 5
```

Opcionalmente é possível passar uma função para transformar os elementos antes de verificar, note que os elementos da tabela somente são afetados na verificação, o índice retornado é a posição do primeiro item diferente:

```lua
all("number",{7,9,"a",5,7},function (v) return type(tonumber(v)) end) -- false 3
all("number",{7,9,"6",5,7},function (v) return type(tonumber(v)) end) -- true
```

## String (suporte a Unicode)

As seguintes funções da biblioteca `string` foram reescritas para suportar caracteres Unicode

* **`string.len`**

```lua
-- Lua pura:
("coração"):len() -- 9

-- Lovely:
("coração"):len() -- 7
```

* **`string.sub`**
```lua
-- Lua pura:
("coração"):sub(2,5)  -- ora�
("coração"):sub(5,7)  -- ç�
("coração"):sub(3,-3) -- raç�

-- Lovely:
("coração"):sub(2,5)  -- oraç
("coração"):sub(5,7)  -- ção
("coração"):sub(3,-3) -- raç
```
* **`string.lower`**

```lua
-- Lua pura:
("CORAÇÃO"):lower() -- coraÇÃo

-- Lovely:
("CORAÇÃO"):lower() -- coração
```

* **`string.upper`**

```lua
-- Lua pura:
("coração"):upper() -- CORAçãO

-- Lovely:
("coração"):upper() -- CORAÇÃO
```

* **`string.reverse`**

```lua
-- Lua pura:
("coração"):reverse() -- o�ç�aroc

-- Lovely:
("coração"):reverse() -- oãçaroc
```

## String (iteradores)

* **`string.lines`**

Itera para cada linha na string, divide a string pelo delimitador de quebra de linha (CRLF e LF) e retorna um iterador, é um _syntax sugar_:

```lua
-- Lua pura:
for linha in str:gmatch("[^\r\n]+")) do
  print(linha)
end

-- Lovely:
for linha in str:lines() do
  print(linha)
end
```

Para ter o mesmo efeito de `str:gmatch("[^\r\n]*"))`, passe `true` para `string.lines`:

```lua
-- Lua pura:
for linha in str:gmatch("[^\r\n]*")) do
  print(linha)
end

-- Lovely:
for linha in str:lines(true) do
  print(linha)
end
```

* **`string.chars`**

Itera para cada caractere na string usando a biblioteca Unicode, é um _syntax sugar_:

```lua
-- Lua pura:
for _, caractere in utf8.codes(str) do
  caractere = utf8.char(caractere)
  print(caractere)
end

-- Lovely:
for caractere in str:chars() do
  print(caractere)
end
```

* **`string.split(str,separator,strip_quotes)`**

Itera trechos de uma string separados por um caractere, esse método mantém unidos os trechos delimitados por `"` e `'`, opcionalmente pode se remover as aspas no inicio e final de cada truecho passando `true` no terceiro parâmetro:

```lua
for i,excerpt in ('1,2,"3,14",4'):split(",",true) do
  print(excerpt)
end
-- 1
-- 2
-- 3,14
-- 4
```


## String (aparadores)

* **`string.ltrim`** Remove espaços em branco a esquerda
* **`string.rtrim`** Remove espaços em branco a direita
* **`string.htrim`** Remove espaços em branco em ambos os lados
* **`string.itrim`** Remove espaços em branco duplicados dentro da string
* **`string.trim`**  Combinação de `ltrim`,`rtrim`,`htrim` e `itrim`

# Verificando se o Lovely foi carregado e qual versão foi

O Lovely inclui uma variável especial com a informação da versão a existência dessa variável indica que o Lovely foi  carregado e os indicices de 1 a 3 indicam respectivamente os campos Major, Minor e Patch da versão carregada:

```lua
if __LOVELY_VERSION__ then
  print("Lovely carregado, versão:")
  print("  - Major:"..__LOVELY_VERSION__[1])
  print("  - Minor:"..__LOVELY_VERSION__[2])
  print("  - Patch:"..__LOVELY_VERSION__[3])
else
  print("Lovely não carregado")
end
