# Hilbish Module Template

This is a demonstration of how to configure the
[Hilbish shell](https://github.com/Rosettea/Hilbish) using
`nix-wrapper-modules`.

It showcases the powerful feature of injecting Nix options directly into a
standalone Lua configuration, specifically tailored for the Hilbish environment.

## File Structure

- `flake.nix`: The entry point that defines inputs and outputs.
- `module.nix`: The Nix module where you define custom options (like
  `myConfig.greeting`), pass them to `luaInfo`, and specify the path to your Lua
  entrypoint.
- `lua/init.lua`: Your pure Lua Hilbish configuration. It pulls in the Nix
  values dynamically using `require('nix-info')`.

## Usage

To initialize this template flake into an empty directory, run:

```bash
nix flake init -t github:BirdeeHub/nix-wrapper-modules#hilbish
```

To build and run it from this directory:

```bash
nix build .
./result/bin/hilbish
```

### 2. Posso ancora eseguire i vecchi comandi e script Bash?

Assolutamente SÌ, al 100%! Non perdi assolutamente nulla. Ecco come funziona:

- I comandi di tutti i giorni ( ls , grep , git , nixos-rebuild , ecc.): Li
  scrivi in Hilbish esattamente come facevi in Bash. Questo perché git o grep
  non sono comandi di Bash, ma programmi indipendenti installati sul tuo PC.
  Hilbish li cerca e li esegue proprio come faceva Bash.
- I vecchi script Bash ( .sh ): Se hai uno script bash chiamato script.sh , puoi
  lanciarlo scrivendo ./script.sh oppure bash script.sh . Funzionerà
  perfettamente perché dentro lo script c'è scritto #!/usr/bin/env bash (o
  #!/bin/bash ). Quando Hilbish legge quella riga, capisce che è roba vecchia e
  "chiama" segretamente Bash in background per fargli eseguire il file al  
  posto suo.

L'unica vera differenza (Cosa NON puoi fare in Hilbish): Non puoi incollare e
usare la sintassi interna di Bash direttamente nella riga di comando di Hilbish.
Ad esempio:

- In Bash per creare una variabile d'ambiente scrivevi: export CIAO=1
- In Hilbish scrivi direttamente: os.setenv("CIAO", "1")

### 1. Pipe ( | ) e Reindirizzamenti ( > , >> , < )

Funzionano esattamente come in Bash! Hilbish è scritta in modo intelligente:
quando digiti un comando interattivo, capisce la sintassi POSIX standard. Se nel
tuo terminale Hilbish scrivi: ls -la | grep "documenti" > log.txt  
Funzionerà al 100% al primo colpo! Hilbish si occupa nativamente di prendere
l'output del primo programma e "infilarlo" nel secondo proprio come faceva Bash.

### 2. xargs , parallel , find , awk

Questi NON sono comandi di Bash, ma sono programmi (eseguibili binari) scritti
in C creati decenni fa dal progetto GNU, che vivono nel tuo sistema operativo
NixOS. Bash si limitava a richiamarli, ed Hilbish fa la stessa identica cosa.
Quindi puoi tranquillamente scrivere: find . -name "\*.txt" | xargs rm e
funzionerà alla perfezione.

### 3. Eseguire codice puramente Bash (il "bash(...)")

Se hai un blocco di codice con sintassi specifica di bash (es. i famosi cicli
for i in {1..10} ) e vuoi eseguirlo letteralmente usando bash, hai due modi:

- Da terminale interattivo: Basta chiamare bash e passargli la stringa:
  `bash -c "for i in {1..10}; do echo \$i; done"`
- Da dentro lo script Lua (il tuo init.lua ): Se stai scrivendo il tuo config in
  Lua e vuoi usare una funzione bash complessa, hai le funzioni native di Lua
  per farlo:
  - os.execute('bash -c "tuo comando bash"') (Lo esegue e basta, come il vecchio
    system() ).
  - io.popen('bash -c "tuo comando bash"') (Lo esegue e cattura l'output per
    fartelo usare in Lua, come ho fatto per farti leggere il comando di Git nel
    prompt!).

### 1. Come eseguire uno script .lua esterno con Hilbish

Hai esattamente due modi comodissimi, proprio come faresti con Bash o Python:

- Modo A (Manuale): Dal terminale, scrivi semplicemente hilbish
  percorso/dello/script.lua . Hilbish leggerà il file, eseguirà il codice Lua e
  poi si chiuderà.
- Modo B (Eseguibile nativo): Se apri il tuo file .lua e scrivi come primissima
  riga in alto il "shebang" #!/usr/bin/env hilbish , puoi renderlo un eseguibile
  a tutti gli effetti (es. chmod +x script.lua ). A quel punto potrai  
  lanciarlo scrivendo solo ./script.lua .

### 1. Stampare (Listare) Opzioni e Alias

Se vuoi vedere quali alias hai impostato e a cosa corrispondono, ti basta
scrivere un mini-ciclo Lua nel prompt e premere Invio:

for nome, comando in pairs(hilbish.aliases) do print(nome, comando) end

(Questo è l'equivalente del comando alias di Bash, ma ti permette di filtrare,
cercare o formattare il testo come preferisci usando le potenzialità di Lua!).

Se vuoi vedere tutte le impostazioni interne:

`for k, v in pairs(hilbish.opts) do print(k, v) end`

### 2. Modificare il comportamento "A Caldo" (Runtime)

Esattamente come chiedevi, puoi alterare il funzionamento di Hilbish
temporaneamente per quella singola sessione.  
Mettiamo caso che io voglia disattivare l'autocompletamento "fuzzy" che abbiamo
acceso prima, ti basta scrivere questo nel terminale:

`hilbish.opts.fuzzy = false`

Premi Invio, e da quell'esatto millisecondo il fuzzy search è spento.  
Vuoi disattivare temporaneamente la cronologia dei comandi per non salvare
comandi con password in chiaro?

`hilbish.opts.history = false`

### 3. Quante variabili/opzioni ha?

Attualmente la tabella centrale hilbish.opts è molto "pulita" e ha circa 8/10
opzioni principali (ad esempio autocd per entrare nelle cartelle digitando solo
il nome, history , fuzzy , notifyJobFinish per avere un alert quando  
un lavoro in background finisce, e il saluto greeting ).

Tuttavia, il vero potere non è in opts , ma negli altri sottomoduli! Ad esempio:

- hilbish.jobs : Contiene in tempo reale la lista di tutti i processi che hai
  mandato in background.
- hilbish.timers : Per gestire timer e task asincroni.
- hilbish.editor : Per cambiare al volo le regole di come leggi i caratteri o
  accendere la Vim Mode ( hilbish.editor.vimMode(true) ). - - La filosofia di
  Hilbish è: "Non ti do un milione di opzioni preimpostate come Zsh. Ti do un
  cuore in Go velocissimo e ti espongo tutti gli ingranaggi interni tramite Lua,
  così te la plasmi tu."
