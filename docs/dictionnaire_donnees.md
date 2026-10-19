# Dictionnaire initial des données — version 0.1

Date : 18 octobre 2026. Statut : contrat implémenté par le générateur, tests
unitaires et rapport qualité disponibles ; sauvegardes brutes préservées.
Projet personnel indépendant de l'UPEC, données exclusivement synthétiques.

## Conventions et clés

Identifiants : chaînes sans signification personnelle, stables. Dates : `Date`
au format ISO. Années : `2023-2024`, `2024-2025`, `2025-2026`. Valeurs absentes :
`NA` typé, avec motif si nécessaire, jamais une sentinelle telle que -99.
Clés, références, année et statuts d'éligibilité sont obligatoires.

| Table | Unité et clé primaire | Références et unicité |
|---|---|---|
| etudiants | Personne ; id_etudiant | Stable sur toutes les années |
| formations | Formation fictive ; id_formation | Cycle licence ou master |
| inscriptions | Inscription principale annuelle ; id_inscription | id_etudiant, id_formation ; unique étudiant/année |
| resultats | Décision annuelle ; id_inscription | Une ligne par inscription éligible, inconnus compris |
| parcours | Transition dérivée ; id_inscription_depart | Inscriptions de départ et suivante, cette dernière nullable |
| invitations_evaluation | Invitation ; id_invitation_evaluation | id_inscription ; unique inscription/vague |
| evaluations | Réponse, même partielle ; id_reponse_evaluation | id_invitation_evaluation unique |
| decisions_diplome | Décision terminale ; id_inscription | Une par inscription éligible L3/M2 |
| diplomes | Attribution effective ; id_diplome | id_inscription unique |
| invitations_devenir | Invitation ; id_invitation_devenir | id_diplome ; une par personne dans la vague |
| devenir_diplomes | Réponse ; id_reponse_devenir | id_invitation_devenir unique |

Les invitations existent indépendamment des réponses ; aucune ligne de réponse
ne sera créée pour une non-réponse totale. Les décisions de diplôme sont
distinctes des attributions, pour distinguer non et inconnu. Le parcours est
dérivé des inscriptions et résultats, jamais simulé indépendamment. Contrôler
les cardinalités de jointure avant tout calcul pour éviter les doubles comptes.

## Variables métier proposées

Les clés et références ci-dessus s'ajoutent aux champs ci-dessous.

| Table | Champs | Types, domaines et manquants |
|---|---|---|
| etudiants | type_bac | general, technologique, professionnel, autre ; NA possible |
| etudiants | motif_type_bac_manquant | non_disponible si type_bac NA ; NA sinon |
| etudiants | parcours_anterieur | entree_postbac, reprise_etudes, autre ; NA possible |
| formations | libelle_formation, cycle | Libellé fictif obligatoire ; licence ou master |
| inscriptions | annee_universitaire, niveau | Années du panel ; L1, L2, L3, M1, M2 compatibles avec cycle |
| inscriptions | date_inscription, statut_inscription | Date ; active ou annulee au 31 octobre, obligatoires |
| inscriptions | boursier | Logique annuelle, NA possible, pas un attribut immuable |
| inscriptions | motif_boursier_manquant | non_disponible si boursier NA ; NA sinon |
| inscriptions | prerequis_valides | Logique obligatoire en niveau terminal ; acquis antérieurs documentés |
| resultats | validation_annuelle | oui, non, inconnu, obligatoire |
| resultats | motif_resultat_inconnu | non_disponible ou dossier_incomplet si inconnu ; NA sinon |
| resultats | moyenne_annuelle, ects_acquis | Numérique 0–20, entier 0–60 ; NA possibles ; ne remplacent pas la décision |
| resultats | date_decision | Date connue si décision oui/non ; pas après gel annuel |
| parcours | etat_transition | passage, redoublement, reorientation, sortie_observee, poursuite_intercycle, autre, non_observable |
| parcours | id_inscription_suivante | Référence absente si sortie ou transition non observable |
| invitations_evaluation | vague, date_ouverture, date_cloture | Vague annuelle et dates de juin obligatoires |
| invitations_evaluation | statut_reponse | aucune, partielle, complete, obligatoire à la clôture |
| evaluations | date_reponse | Date dans la fenêtre de collecte |
| evaluations | satisfaction_globale, satisfaction_contenus, satisfaction_accompagnement | Entiers 1 à 5, NA possibles |
| evaluations | motif_satisfaction_globale, motif_satisfaction_contenus, motif_satisfaction_accompagnement | non_reponse_item ou non_concerne si item NA ; NA sinon |
| decisions_diplome | attribution_diplome, date_decision_diplome | oui, non, inconnu ; date NA si inconnu, sinon au plus tard au gel |
| diplomes | type_diplome, date_diplome | licence après L3 ou master après M2 ; date cohérente avec décision |
| invitations_devenir | vague, date_reference | Identifiant de vague ; date diplôme + six mois calendaires |
| invitations_devenir | date_ouverture, date_cloture | Sixième au septième mois ; fenêtre close au gel |
| invitations_devenir | statut_reponse | aucune, partielle, complete, obligatoire à la clôture |
| devenir_diplomes | date_reponse | Date dans la fenêtre de collecte |
| devenir_diplomes | situation_six_mois | etudes, emploi_hors_etudes, recherche_emploi_hors_etudes, autre_hors_etudes ; NA si inconnue |
| devenir_diplomes | motif_situation_manquante | non_reponse_item ou ne_sait_pas si situation NA ; NA sinon |
| devenir_diplomes | emploi_pendant_etudes | Logique si situation etudes ; NA sinon ou si inconnu |
| devenir_diplomes | motif_emploi_pendant_etudes_manquant | non_applicable hors études ; non_reponse_item si études et item NA ; NA sinon |

Le calcul des mois utilise le dernier jour valide lorsque le jour initial
n'existe pas dans le mois cible. Codes de formation et paramètres sont dans
`config/simulation.R` ; libellés, filtres et complétude dans `docs/questionnaires.md`.
Le référentiel formations contient aussi `poids_dans_cycle`, numérique strictement
positif, dont la somme vaut 1 dans chaque cycle ; il s'agit d'un paramètre de
simulation, jamais d'un poids de redressement d'enquête.

`metadata` accompagne les onze tables : provenance entièrement synthétique,
version du simulateur, copie de la configuration et indicateur d'anomalies.
L'injecteur retourne `data` (copie altérée) et `issues` (journal) ; ce dernier
contient id_anomalie, type, table, ligne, cle, champ, valeur_initiale,
valeur_injectee et controle_attendu. Les indices désignent les lignes de la
copie retournée ; conserver le journal avec cette version, avant tout tri.

## Contrôles et rapports

Les sauvegardes du notebook 01 sont `data/raw/base_synthetique.rds` (onze tables
et metadata), `data/raw/base_synthetique_anomalies.rds` (copie altérée) et
`data/raw/journal_anomalies.rds` (journal de 50 injections). Le manifeste
`data/raw/manifest_generation.csv` contient objet, fichier, provenance,
version_simulateur, date_gel, version_r_ecriture, n_etudiants, n_inscriptions,
n_anomalies, octets et md5. Les effectifs étudiants et inscriptions du journal
sont non applicables. Les fonctions de stockage conservent les objets sans
nettoyage et vérifient l'intégrité avant relecture.

Clés uniques, références valides, domaines, cohérence des dates et niveaux,
décisions annuelles et diplômes compatibles, invitations exhaustives des
éligibles et réponses non dupliquées. Reconstituer le statut de réponse à partir
des items pour le comparer au statut déclaré. Les acquis antérieurs au panel
restent des prérequis simulés, pas des inscriptions observées inventées.

La copie d'anomalies est séparée et accompagnée d'un journal indiquant règle,
table, clé, valeur initiale, valeur injectée et contrôle attendu. Les types
prévus incluent doublons, références orphelines, domaines et dates invalides,
incohérences de résultat et transitions impossibles.

`R/quality/check_quality.R` applique le contrat sans corriger les tables. Les
rapports du notebook 03 distinguent contrôles conformes, non conformes et non
exécutés. Le détail comporte règle, table, ligne, clé, champ, valeur observée,
sévérité et description ; l'ordre des lignes est celui de la variante brute.
Les jointures n'utilisent pas de référence ambiguë pour conclure à la conformité.
Le journal des injections est rapproché des alertes sur règle/table/ligne/champ.
Les sorties dans `outputs/qualite/` conservent les empreintes des sources,
la version des contrôles et l'environnement d'exécution.

## Tables préparées — étape 17

`R/data/clean_data.R` restaure uniquement les valeurs initiales documentées
du journal synthétique et supprime les copies strictes explicitement ajoutées.
Les valeurs manquantes et leurs motifs sont préservés. Une anomalie résiduelle,
une cible modifiée ou un doublon non identique bloque la préparation.

`data/processed/` conserve les onze tables normalisées en RDS, sans changement
de schéma, ainsi que `scolarite_analytique.rds` (clé `id_inscription`). Cette
dernière associe inscriptions, étudiants, formations, résultats et parcours
par des jointures contrôlées plusieurs-vers-un. Les diplômes et enquêtes
restent dans leurs tables séparées.

| Champ ajouté à la table analytique | Type | Définition |
|---|---|---|
| `decision_connue` | logical | TRUE pour validation `oui` ou `non`, FALSE pour `inconnu` |
| `cible_reussite` | logical | TRUE si validation `oui`, FALSE si `non`, NA si inconnue |
| `transition_observable` | logical | FALSE pour 2025-2026, dernière année censurée ; TRUE pour les deux années précédentes |

Les colonnes sources conservent leurs définitions et leurs motifs d'absence.
`metadata.rds` conserve l'origine synthétique, l'historique des injections et
la version du nettoyage. `audit_nettoyage.rds` contient journal des actions,
contrôles avant/après, comparaison avec la référence et empreintes des sources.
`manifest_preparation.csv` liste objets, fichiers, lignes si applicables,
tailles et MD5. Les données de travail restent exclues de Git.
