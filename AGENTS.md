# AGENTS.md — homebrew-projump

## Produit

Tap Homebrew de l'organisation `projump` : il distribue le Cask macOS de Projump
(`brew install --cask projump/projump/projump`). L'application elle-même vit dans
`github.com/projump/projump`.

## Carte du code

- `Casks/projump.rb` : le Cask distribué (version, SHA-256, URL de l'archive de release,
  `Projump.app`, contrainte macOS, `zap`).
- `test/cask_contract.rb` : lecteur minimal du DSL Cask (`CaskContract::Recorder`) et
  validateur du contrat (`CaskContract.errors`) ; les valeurs attendues sont les constantes
  en tête du module.
- `test/projump_cask_test.rb` : tests minitest — le Cask actuel est conforme, des variantes
  incohérentes construites en mémoire sont rejetées.
- `README.md` : installation et commandes de développement.

## Commandes

```sh
ruby -c Casks/projump.rb        # syntaxe du Cask
ruby test/projump_cask_test.rb  # contrat du Cask, hors ligne
git diff --check
```

## Conventions

- Ruby système (2.6 sur la machine de l'usine) : bibliothèque standard et minitest uniquement,
  sans Gemfile ni gem, sans Homebrew ni réseau dans les tests.
- La version distribuée (`version`, `sha256`) ne change que lors d'une release.
- Un changement volontaire du contrat (nom de l'app, contrainte macOS, gabarit d'URL) passe par
  la modification des constantes de `test/cask_contract.rb` dans le même changement.

## Livraison

1. Publier la release GitHub `v<version>` de `projump/projump` avec `Projump-<version>.zip`.
2. Mettre à jour `version` et `sha256` (`shasum -a 256 dist/Projump-<version>.zip`) dans
   `Casks/projump.rb`.
3. Lancer les commandes ci-dessus, puis ouvrir une PR (pas de fusion automatique).

## Travail dans l'usine

- Validation de l'usine : `ruby -c Casks/projump.rb && git diff --check` ; lancer aussi
  `ruby test/projump_cask_test.rb`.
- Ni commit, ni push, ni release : le moteur livre la PR.

## Pièges connus

- Ruby système 2.6 : pas de syntaxe ≥ 2.7 (`filter_map`, `Hash#except`, pattern matching,
  paramètres numérotés) dans `test/`.
- `version` sans argument doit renvoyer la valeur enregistrée : c'est ce qui fait fonctionner
  `#{version}` dans `url` (`CaskContract::Recorder#version`).
- Toute nouvelle stanza du Cask fait échouer le chargement (`unknown cask stanza`) : l'ajouter à
  `CaskContract::Recorder` dans `test/cask_contract.rb`.
