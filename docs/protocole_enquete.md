# Protocole d'enquête — évaluation et devenir des diplômés

Étape 21, version 0.1. Démonstrateur personnel indépendant de l'UPEC.
Données et identifiants exclusivement synthétiques ; aucune collecte réelle.

## Finalités et univers

L'évaluation décrit la participation et les réponses de satisfaction, pour
préparer un échange avec les responsables de formation. L'insertion décrit
la situation déclarée à six mois des diplômés de référence observables.
Les résultats ne constituent ni une évaluation officielle de l'UPEC ni des
preuves d'efficacité ou d'effets causaux des formations.

Évaluation : une invitation pour chaque inscription principale active et
chaque vague de juin 2024, 2025 et 2026. Collecte du 1er au 30 juin. Un étudiant
peut contribuer à plusieurs vagues ; les restitutions principales restent
annuelles, sans tests supposant l'indépendance des réponses cumulées.

Devenir : date de référence à six mois du diplôme, collecte du sixième au
septième mois, close au gel du 30 septembre 2026. Retenir le diplôme mature
le plus récent par personne, selon le protocole statistique. Les diplômes
plus anciens éligibles non retenus et les collectes non closes sont dénombrés
séparément. Un diplôme immature n'est pas une non-réponse.

## Questionnaire type à transposer dans LimeSurvey

Le fichier `docs/questionnaires.md` contient les libellés et modalités stables.
La présente spécification est un modèle de paramétrage : aucun fichier `.lss`
ni import sur une instance LimeSurvey n'a été testé. Aucun envoi n'est effectué.

| Groupe | Code | Type prévu | Obligatoire | Pertinence proposée |
|---|---|---|---|---|
| Accueil | PARTICIPATION | Oui/non | Oui pour poursuivre | 1 |
| Évaluation | EVAL_GLOBAL | Liste à choix unique | Non | `PARTICIPATION == 'Y'` |
| Évaluation | EVAL_CONTENUS | Liste à choix unique | Non | `PARTICIPATION == 'Y'` |
| Évaluation | EVAL_ACCOMP | Liste à choix unique | Non | `PARTICIPATION == 'Y'` |
| Devenir | DEV_SITUATION | Liste à choix unique | Non | `PARTICIPATION == 'Y'` |
| Devenir | DEV_EMP_ETUDES | Oui/non | Non | `PARTICIPATION == 'Y' and DEV_SITUATION == 'etudes'` |

Les deux modules sont prévus comme deux enquêtes distinctes, avec les mêmes
conventions de participation ; ils ne sont pas présentés à tous les inscrits
dans un formulaire commun. Le texte d'accueil annonce la finalité simulée,
la possibilité de ne pas répondre et l'absence de diffusion individuelle.
La question de participation est une spécification future, pas une preuve
de consentement enregistrée dans les tables synthétiques existantes.

Les expressions de pertinence contrôlent l'affichage des questions selon
[le manuel ExpressionScript](https://www.limesurvey.org/manual/ExpressionScript_-_Presentation).
Les expressions, codes et types devront être vérifiés dans l'instance retenue
avec l'outil de contrôle de logique avant toute activation.

### Modalités et normalisation

- Évaluation : codes 1 à 5, de très insatisfait à très satisfait, plus `NC`.
  Pas de réponse précochée. `NC` devient `NA` avec `non_concerne` ; vide devient
  `NA` avec `non_reponse_item`. Conserver une invitation sans ligne de réponse
  pour la non-réponse totale ; ne pas lui inventer un motif d'item.
- Situation : `etudes`, `emploi_hors_etudes`, `recherche_emploi_hors_etudes`,
  `autre_hors_etudes`, `NSP`. Alternance et activité étudiante restent en
  `etudes` pour la situation principale. `NSP` devient `ne_sait_pas`, vide
  devient `non_reponse_item`. Ces deux motifs restent distincts, même si
  le simulateur actuel ne génère que le second pour cet item.
- Emploi pendant études : Y/N devient TRUE/FALSE uniquement si situation
  `etudes`. Hors champ ou situation inconnue : NA, `non_applicable`.
  Si applicable et vide : NA, `non_reponse_item`. Un changement de situation
  doit effacer une ancienne réponse devenue hors champ, à tester au pilote.

Les codes exportés, dates et identifiants d'invitation sont conservés sans
inventer de valeurs manquantes négatives. Aucun nom, courriel, commentaire
libre ou numéro étudiant réel n'est nécessaire au démonstrateur.

## Invitations, rapprochement et confidentialité du démonstrateur

Le modèle de données permet le rapprochement invitation/réponse avec des clés
fictives, pour comparer répondants et population invitée. Dans une transposition
technique, cela correspondrait à des réponses reliables, pas à une promesse
d'anonymat irréversible. LimeSurvey indique que son option de réponses anonymisées
empêche le rapprochement participant/réponse ; elle ne convient donc pas à ce
scénario de liaison individuelle ([paramètres de participation](https://www.limesurvey.org/manual/Participant_settings)).

Un éventuel dispositif réel devrait choisir et documenter son architecture
avant collecte. Ici, aucune instance n'est connectée et aucun réglage n'est
modifié. Les tables de travail et les sorties individuelles synthétiques
restent exclues de Git ; seuls code, protocole et notebook sont versionnables.

## Calendrier et recette de collecte simulée

Prévoir un pilote avant la vague : compréhension des libellés, affichage sur
petit écran, distinction « non concerné »/vide, parcours sans participation,
reprise d'une réponse, changement études vers emploi et export des codes.
Pour l'évaluation, un scénario professionnel pourrait prévoir invitation au
1er juin, deux relances des non-répondants les 10 et 20 juin et clôture au
30 juin. Ces dates sont un plan, pas des messages envoyés par le projet.
Le devenir suit les fenêtres individuelles déjà présentes dans les invitations.

Recette minimale avant un futur import réel de démonstration :

1. Vérifier codes, libellés, pertinence et absence de choix par défaut.
2. Tester les branches participation non, situation vide/NSP/études/hors études.
3. Tester NC, item vide, réponse partielle et questionnaire complet.
4. Exporter un petit jeu fictif et contrôler dates, clés et correspondances.
5. Détecter les doublons ; ne pas garder silencieusement la dernière réponse.
6. Reconstituer les statuts et vérifier une seule réponse retenue par invitation.

## Plan d'exploitation statistique

I06 : répondants avec au moins un item renseigné (1 à 5 ou NC), divisés par
toutes les invitations. Décompter également les questionnaires complets.
Un statut « soumis » d'un outil de collecte ne remplace pas cette définition.

I07 : réponses 4/5 sur toutes les réponses numériques 1 à 5 de l'item global.
Publier les cinq modalités, la non-réponse à la vague, à l'item, les NC et la
couverture numérique sur invitations. Les trois exclusions ne sont ni des
insatisfactions ni une unique catégorie « réponse négative ».

Comparer par année la composition des invités et répondants selon bourse,
bac, niveau et formation, en gardant les caractéristiques manquantes visibles.
Le croisement avec la décision annuelle est rétrospectif : la décision définitive
de septembre n'était pas nécessairement disponible en juin. Il ne constitue
pas un critère utilisé pour adresser les invitations de juin.

Le simulateur programme une participation plus faible chez les boursiers
latents, dont le statut peut être masqué dans la table observée. Un écart de
composition peut donc apparaître. Il décrit une sélection sur caractéristiques
observées ; il ne quantifie pas le biais de satisfaction des non-répondants,
dont les réponses ne sont pas connues. Aucun poids de redressement n'est créé
sans hypothèses et marges justifiées. Ne pas conclure à la représentativité
à partir du seul taux de réponse.

### Fiabilité des items

Les trois items portent sur des dimensions distinctes et sont tirés
indépendamment dans le simulateur, sans variable latente commune. La condition
de construction d'une échelle réflexive unique n'est donc pas établie.
Ne calculer ni score composite ni alpha de Cronbach présenté comme validation
de cette échelle. Le notebook décrit seulement les corrélations de rang de
Spearman par paires complètes et par année, avec les effectifs associés.
Des corrélations faibles ne prouvent pas que chaque question est inutile.
Une étude psychométrique demanderait un instrument conçu pour ce besoin,
une validation de contenu et une étude de sa structure.

### Devenir et insertion

I09 compte les situations connues parmi toutes les invitations éligibles,
pas seulement les questionnaires reçus. Publier ces deux participations.
I10 rapporte l'emploi hors études aux situations connues hors études (emploi,
recherche ou autre). I11 rapporte les études à toutes les situations connues.
Décrire l'emploi pendant les études séparément, avec sa couverture applicable.
Conserver le type et l'année du diplôme ; les personnes retenues ne représentent
pas tous les diplômes attribués et aucune cohorte 2025-2026 immature n'est
classée non-répondante. I10 n'est ni un taux de chômage ni un taux officiel
d'insertion ; I10 et I11 ont des dénominateurs différents.

## Restitution et reproductibilité

Le notebook `07_evaluation_formations.qmd` produit les tableaux et graphiques
avec des taux absents pour un dénominateur inférieur à dix, et les effectifs
permettant de vérifier chaque formule. Ces sorties techniques nécessiteraient
un examen complémentaire des petits effectifs avant une publication réelle.
Pas de classement des formations ni de conclusion causale.

Les fonctions sont dans `R/surveys/analyse_surveys.R`. Sources préparées et
brutes restent inchangées ; empreintes, session et configuration tracent les
analyses. Les recommandations portent sur la lecture des indicateurs et la
qualité du dispositif de collecte, sans action réelle sur des personnes.
