# Protocole statistique — version 0.1

Date : 18 octobre 2026. Statut : décisions D01 à D07 validées lors du passage
à la préparation de la simulation ; paramètres et questionnaires acceptés au
démarrage de la génération de la phase B.
Projet personnel indépendant de l'UPEC ; données exclusivement synthétiques.

## Unités, populations et calendrier

- **Étudiant** : personne fictive identifiée par `id_etudiant`, stable sur le suivi.
- **Inscription** : inscription principale d'un étudiant dans une formation et un
  niveau pendant une année ; une au maximum par personne et année en version 1.
- **Population annuelle** : personnes ayant une inscription active, non annulée,
  au 31 octobre de l'année de début de l'année universitaire. Une inscription
  annulée avant cette date est exclue des indicateurs annuels et recensée à part.
- **Cohorte d'entrée** : première inscription observée en L1 dans le champ en
  2023-2024 ou après. La première apparition en L2 ou M1 n'est pas une entrée L1.
  « Première observée » ne signifie pas première inscription dans le supérieur.
- **Population d'enquête** : liste des personnes éligibles à une vague, définie
  avant les réponses. Elle inclut les invités qui ne répondront pas.

Le panel couvre 2023-2024, 2024-2025 et 2025-2026. Les résultats annuels sont
arrêtés après seconde session, au 30 septembre suivant chaque année. Le gel
scolaire de 2025-2026 est donc proposé au 30 septembre 2026. Les transitions
utilisent les inscriptions au 31 octobre suivant : seules 2023-2024 → 2024-2025
et 2024-2025 → 2025-2026 sont observables ici. Aucune sortie ne sera déduite
de l'absence de données 2026-2027.

## Réussite académique : cible principale

Définition proposée : décision annuelle définitive de validation du niveau après
les sessions prévues, codée `validation_annuelle` (oui/non/inconnu). Une moyenne,
un crédit acquis, une présence à un examen et une obtention de diplôme ne
remplacent pas cette décision. Les moyennes et ECTS servent aux contrôles de
cohérence ; les règles de compensation seront propres au simulateur, pas celles
d'une formation réelle de l'UPEC.

Le taux principal porte sur les inscriptions annuelles éligibles dont la décision
est connue : validées / (validées + non validées). Les résultats inconnus restent
hors de ce dénominateur et leur proportion est publiée à côté. Un étudiant absent
aux examens ne devient « non validé » que si une décision définitive le précise.

Analyse de sensibilité prévue : validées / toutes les inscriptions éligibles,
présentée comme borne basse descriptive en présence d'inconnus, sans convertir
ces inconnus en échecs individuels. Si le dénominateur est nul, le taux vaut `NA`,
jamais zéro. Les comparaisons entre formations exigent de vérifier la couverture
des résultats et la structure des niveaux et cohortes.

## Parcours et transitions

Une ligne dérivée par inscription principale de l'année de départ. L'état dépend
de l'inscription principale de l'année suivante. Appliquer cet ordre exclusif :

1. Dernière année du panel : **non observable**, transition censurée.
2. Aucune inscription dans l'année suivante pourtant observable : **sortie
   observée du champ**, sans conclure à un abandon ni à une sortie du supérieur.
3. Changement de cycle L3 → M1 après validation de L3 : **poursuite intercycle**,
   même si le code de formation change ; ne pas la compter comme réorientation.
4. Autre changement de `id_formation` : **réorientation interne observée**.
5. Même formation, niveau immédiatement supérieur et validation de l'année
   précédente : **passage** (L1 → L2, L2 → L3 ou M1 → M2).
6. Même formation, même niveau et non-validation définitive : **redoublement**.
7. Toute autre combinaison : **autre transition**, à documenter et contrôler.

Dans le modèle simplifié, les sauts de niveau et régressions au sein d'une même
formation sont interdits ; une combinaison impossible bloque la base cohérente.
Un résultat inconnu ne suffit pas à qualifier un passage ou un redoublement.
La réorientation est définie par un changement de formation hors articulation
L3 → M1 et ne prouve ni une préférence ni une difficulté académique.

La sortie observée sera croisée avec la diplomation, sans modifier sa définition.
Un diplômé de M2 sans réinscription n'est donc pas décrit comme un décrocheur.
Une personne absente une année puis de retour conserve son identifiant ; cette
absence reste une sortie observée annuelle, sans qualification définitive.

### Mise en œuvre du suivi longitudinal — étape 22

Le notebook `08_analyse_longitudinale.qmd` et les fonctions dans
`R/analysis/longitudinal.R` reconstruisent les liens étudiant/année et vérifient
leur concordance avec les transitions stockées. Les premières observations
en L1 définissent trois cohortes distinctes ; les autres niveaux initiaux
restent hors de ces cohortes, tout en contribuant aux transitions de l'ensemble
du panel. Le suivi produit une grille personne/année limitée à la période
postérieure ou égale à l'entrée observée et présente dans le panel.

À chaque horizon, la présence est rapportée à l'effectif initial de la cohorte,
y compris les membres absents à cette date. Les transitions de cohorte ont un
autre dénominateur : les inscriptions présentes à l'année de départ. Les
transitions non observables sont exclues, sans devenir des sorties. Une
éventuelle réentrée est conservée, même si le simulateur ne programme pas ce
cas. Les tests utilisent un cas indépendant d'absence puis retour.

Comparer les cohortes à horizon 1 pour 2023-2024 et 2024-2025 ; l'horizon 2
n'est disponible que pour 2023-2024. Aucun horizon 1 n'est attribué à la cohorte
2025-2026. Les sorties sont croisées avec l'attribution du diplôme de départ,
avec un état non applicable pour les niveaux non terminaux et inconnu lorsque
la décision terminale est inconnue. Aucune durée jusqu'à abandon ni hypothèse
de sortie absorbante n'est introduite.

## Diplômes

Diplômes proposés : licence après L3 et master après M2, uniquement si le cursus
simulé satisfait ses exigences documentées. La validation annuelle est nécessaire
mais la décision d'attribution est enregistrée séparément. Les niveaux antérieurs
des étudiants déjà en L3 ou M2 à l'entrée du panel devront être représentés par
des prérequis synthétiques documentés ; leur passé ne sera pas reconstruit comme
une scolarité observée. Un même étudiant peut obtenir une licence puis un master.

## Enquête d'évaluation des formations

Une vague par année, proposée du 1er au 30 juin de l'année de fin. Population :
inscrits annuels éligibles ; une invitation par inscription principale. Le
questionnaire porte sur la formation suivie, avec items de satisfaction de 1 à 5,
une modalité « non concerné » distincte et des réponses facultatives.

Une réponse exploitable contient au moins un item du module ; une réponse
partielle peut donc contribuer à certains indicateurs. Chaque item a son propre
dénominateur de réponses valides. La satisfaction globale proposée est la part
des modalités 4 ou 5 sur l'item global, accompagnée de toute la distribution.
Une non-réponse à la vague, une non-réponse à l'item et « non concerné » restent
trois états distincts. Aucun score composite ni seuil psychométrique n'est fixé
avant examen de la construction des items et de leur cohérence.

Préparer un questionnaire et un dictionnaire d'export compatibles avec une
future démonstration LimeSurvey : codes stables, filtres, consentement fictif,
horodatage, dictionnaire des valeurs manquantes et séparation invitation/réponse.
Aucune connexion, invitation réelle ou donnée de contact n'est nécessaire ici.

## Enquête de devenir des diplômés

Horizon proposé : **six mois après la date de diplôme**, avec une fenêtre de
collecte du sixième au septième mois et une question sur la situation à six mois.
À la date d'observation synthétique du 30 septembre 2026, seuls les diplômes dont
la fenêtre est close sont éligibles. Les diplômes de septembre 2026 seront donc
hors champ de cette enquête, sans être codés non-répondants.

Si plusieurs diplômes rendent un étudiant éligible, retenir le plus récent par
personne avant constitution de la vague ; conserver `id_diplome` pour la
traçabilité. Les situations de référence sont exclusives : études (y compris
alternance), emploi hors études, recherche d'emploi hors études ou autre
situation hors études. Une réponse inconnue n'est pas une catégorie négative.
Une activité professionnelle pendant les études peut être enregistrée par un
indicateur séparé ; la priorité « études » évite le double comptage principal.

La part en emploi parmi répondants hors études n'est ni un taux de chômage, ni
un indicateur officiel d'insertion. Présenter aussi la poursuite d'études et la
distribution de toutes les situations, avec les effectifs et les non-réponses.

## Hypothèses et analyses futures

Hypothèses exploratoires : les validations pourraient différer selon niveau,
formation, parcours antérieur ou type de bac ; la réponse aux enquêtes pourrait
être socialement et scolairement différenciée. Aucun signe ni effet n'est imposé
comme une vérité sur l'UPEC. Les associations programmées dans le simulateur
seront explicitées : les retrouver ne validera pas une hypothèse empirique.

Commencer par effectifs, distributions, taux et comparaisons de cohortes à durée
de suivi égale. Afficher les dénominateurs, écarts en points et résultats manquants.
Les cohortes entrées tardivement ne seront pas comparées sur trois ans sans
disposer de trois ans de suivi. Les matrices respecteront les états exclusifs.

Une régression logistique exploratoire de la validation pourra être envisagée
si les effectifs, la variation de la cible et l'absence de séparation le
permettent. Vérifier colinéarité, données manquantes, calibration et dépendance
des mesures répétées. Utiliser une seule observation par personne pour une
première analyse ou une méthode tenant compte du regroupement, à justifier.
Séparer les étudiants entre apprentissage et évaluation, sans fuite temporelle ;
ne jamais utiliser comme explicative une variable connue après le résultat cible.
Ne pas installer de package de modélisation avant ce choix.

Le diagnostic de l'étape 19 et la proposition détaillée figurent dans
[Choix du modèle statistique](choix_modele_statistique.md). La proposition
initiale porte sur la coupe 2023-2024, une observation par personne, avec un
GLM binomial-logit et des contrastes de formation dans chaque cycle pour
éviter la redondance avec le niveau. Ce choix a été validé lors du passage à
l'étape 20 ; l'estimation est documentée dans `notebooks/06_modelisation.qmd`.
Le champ n'est pas celui du panel cumulé. La séparation stratifiée 80 % / 20 %
utilise la graine 20261020 ; les étudiants sont disjoints. Les IC de coefficients
sont de Wald à 95 % ; les performances sont mesurées sur test sans réajustement.

Les enquêtes simuleront une non-réponse dépendant de caractéristiques connues,
documentée dans le mécanisme de génération. Comparer répondants et éligibles.
Un redressement éventuel demandera des marges disponibles, une hypothèse de
réponse explicite et une analyse de sensibilité ; aucun poids n'est créé par
défaut. Les données synthétiques n'autorisent aucune inférence sur la population
réelle ; les tests et intervalles éventuels resteront des illustrations de méthode.

### Faisabilité d'une analyse causale — étape 23

Le notebook `09_analyse_causale.qmd` distingue association, prédiction et
intervention, puis examine cohérence, échangeabilité, positivité, temporalité,
interférences et sélection. La question hypothétique d'une offre de tutorat
dispose d'une cible annuelle, mais d'aucune attribution ni réception datée
dans les tables. La satisfaction d'accompagnement ne remplace pas l'exposition
à un dispositif. Aucun effet causal n'est donc estimé avec les données actuelles.

Les comptes formation/niveau documentent des contraintes de support, sans
valider les autres hypothèses. Le graphe proposé sert à discuter une extension,
pas à affirmer des relations prouvées par les données. Les mécanismes programmés
du simulateur restent des hypothèses : leur connaissance ne fournit pas une
preuve sur l'UPEC réelle. Une extension contrefactuelle demanderait un nouveau
protocole, des interventions définies et une vérité synthétique explicitée.

## Qualité, reproductibilité et diffusion

Graines séparées pour population, scolarité, enquêtes et anomalies, paramètres
versionnés, dates de gel fixes et journal des règles. Ne pas utiliser la date
du jour comme paramètre implicite. Contrôler clés, références, domaines, dates,
résultats et transitions avant calcul ; ne pas corriger silencieusement.

Les anomalies seront injectées dans une copie distincte avec type, table, clé,
valeur initiale, valeur injectée et contrôle attendu. Ne pas dégrader la base de
référence. Documenter les `NA` et leurs motifs plutôt qu'utiliser des sentinelles
numériques ambiguës. Aucun nom, adresse ou identifiant réel ne sera généré.

Seuil pédagogique proposé : ne pas afficher de taux pour un dénominateur inférieur
à 10 ; afficher « effectif insuffisant ». Les effectifs nuls sont explicités,
les divisions par zéro donnent `NA`. Pour les tableaux diffusés, prévoir masquage
complémentaire si un petit effectif masqué est déductible par différence. Cette
convention de démonstration n'est pas présentée comme une norme institutionnelle.

## Décisions de cadrage validées

| ID | Proposition | État |
|---|---|---|
| D01 | 15 000 distincts au total, cursus L/M, une inscription principale annuelle | Validée le 18 octobre 2026 |
| D02 | Population figée au 31 octobre, résultats définitifs après seconde session | Validée le 18 octobre 2026 |
| D03 | Réussite parmi décisions connues, couverture et borne basse associées | Validée le 18 octobre 2026 |
| D04 | Transitions exclusives, L3 → M1 distingué, dernière transition censurée | Validée le 18 octobre 2026 |
| D05 | Vagues d'évaluation en juin, item global à cinq modalités | Validée le 18 octobre 2026 |
| D06 | Devenir à six mois, collecte close au gel, situations avec priorité études | Validée le 18 octobre 2026 |
| D07 | Non-affichage des taux sous 10 observations et contrôle des déductions | Validée le 18 octobre 2026 |

La configuration `config/simulation.R`, le plan de simulation et les
questionnaires dans `docs/` précisent les paramètres numériques et les
instruments acceptés pour la version 0.1 du générateur.
