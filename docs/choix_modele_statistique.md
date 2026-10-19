# Étape 19 — Choix du modèle de réussite

Statut : choix validé par la demande de poursuite vers l'étape 20.
Le diagnostic de l'étape 19 a été réalisé sans estimation. L'estimation et
son évaluation sont désormais réalisées dans `notebooks/06_modelisation.qmd`.
Projet personnel indépendant de l'UPEC ; données exclusivement synthétiques.

## Objectif et cible

Décrire des associations ajustées avec la validation annuelle, et illustrer
l'évaluation de probabilités individuelles sur des étudiants non utilisés pour
l'estimation. Il ne s'agit ni d'estimer un effet causal ni de classer les formations.
La cible est binaire parmi les décisions connues : `oui = 1`, `non = 0`.
Les décisions `inconnu` restent manquantes, jamais transformées en échecs.
La diplomation est une autre cible et n'entre pas dans cette modélisation.

Pour cette première estimation, la population proposée est **la coupe initiale
2023-2024**, avec une seule inscription par étudiant, puis restriction aux
décisions connues et aux covariables complètes. Ce choix modifie explicitement
le champ par rapport aux indicateurs descriptifs cumulés sur trois années.
Les résultats ne seront pas présentés comme un modèle de tout le panel.

## Diagnostic réellement exécuté

Commande depuis la racine :

```powershell
Rscript --no-save --no-restore scripts/audit_model_choice.R
```

Le script relit le manifeste et vérifie les empreintes des tables préparées.
Il calcule des effectifs et des matrices explicatives, sans appel à `glm()`,
`glmer()` ni à une autre fonction d'estimation. Les sorties sont conservées dans
`outputs/choix_modele/` : neuf tableaux, manifeste des sources et archive RDS.

| Contrôle | Résultat observé |
|---|---:|
| Inscriptions du panel | 31 816 |
| Étudiants distincts | 15 000 |
| Étudiants avec 1 / 2 / 3 inscriptions | 4 620 / 3 944 / 6 436 |
| Inscriptions de la coupe initiale | 11 000 |
| Décisions connues dans cette coupe | 10 763 |
| Cas complets pour les covariables proposées | 10 397 |
| Validations / non-validations parmi les cas complets | 6 946 / 3 451 |
| Bac manquant parmi les décisions connues | 130 |
| Bourse manquante parmi les décisions connues | 239 |
| Plus petit effectif décision × modalité d'une covariable | 121 |

Les manquants de bac et de bourse se recouvrent : 366 lignes sont exclues pour
covariables incomplètes, et non 369. Le flux complet exclut donc 237 décisions
inconnues puis 366 dossiers incomplets. Ces exclusions seront visibles dans le
notebook 06 ; leur sélection ne doit pas être laissée à un `na.omit` implicite.

La présence des deux décisions dans les modalités marginales est rassurante,
mais **ne démontre pas l'absence de séparation multivariée**. Celle-ci ainsi
que la convergence seront examinées lors de l'estimation, puis dans le seul
échantillon d'apprentissage.

## Formations, niveaux et cohortes

Trois formations fictives de licence couvrent L1/L2/L3 ; deux de master couvrent
M1/M2. Le cycle est déterminé par le niveau et par la formation. Additionner
naïvement `niveau + id_formation` produit 15 colonnes pour un rang de 14.
Ajouter le cycle ne résout pas cette redondance.

La proposition utilise le niveau et trois contrastes de formation dans leur
cycle : licence B versus licence A, licence C versus licence A, master B versus
master A. La matrice obtenue compte 14 colonnes et possède un rang de 14.
Les contrastes de formation restent constants entre niveaux de leur cycle :
c'est une hypothèse additive, pas une comparaison de toutes les formations à
niveau identique lorsqu'elles ne partagent pas ce niveau. Les coefficients de
niveau incluent une comparaison entre les références propres aux deux cycles.
Ils ne mesurent pas un effet isolé de la progression dans les études.

Les premières observations en 2023-2024 comprennent 4 000 L1, 2 500 L2,
2 000 L3, 1 500 M1 et 1 000 M2. Les 2 000 nouveaux observés de chacune des deux
années suivantes sont tous en L1. La première observation en L2/L3/M1/M2
ne constitue pas une entrée en L1. Une régression sur toutes les premières
observations confondrait partiellement calendrier et composition des niveaux.
La coupe initiale évite cette comparaison peu étayée ; année et cohorte y sont
constantes et ne seront pas introduites dans la formule.

## Comparaison des méthodes

| Méthode | Hypothèses et intérêt | Décision pour la première estimation |
|---|---|---|
| GLM binomial, lien logit, coupe initiale | Une réponse binaire par personne ; indépendance entre personnes sous le simulateur ; forme additive du logit à vérifier | Retenu : interprétable, adapté à la cible et disponible dans `stats` |
| GLM naïf sur toutes les inscriptions | Traiterait les mesures d'un même étudiant comme indépendantes | Écarté : 10 380 personnes ont plusieurs observations et le simulateur conserve un effet individuel latent |
| GLMM logistique, intercept aléatoire étudiant | Exploite les répétitions ; suppose une distribution des effets individuels et une indépendance conditionnelle ; coefficients conditionnels | Extension pertinente pour le panel, pas nécessaire à la coupe initiale ; vérifier convergence et singularité si retenue ultérieurement |
| Effet aléatoire formation | Suppose que les cinq formations sont une réalisation d'une population de groupes, avec variance intergroupe estimable | Non retenu : cinq formations fictives, imbriquées dans le cycle, sans objectif de généralisation à de nouvelles formations |
| GEE avec regroupement étudiant ou covariance robuste par étudiant | Associations marginales et prise en compte du regroupement ; hypothèses sur les données observées et le processus de suivi à expliciter | Alternative pour le panel, sans régler à elle seule la sélection liée aux sorties |
| Quasi-binomial seul | Adapte une dispersion scalaire | Ne représente pas à lui seul la covariance des répétitions individuelles |
| Probit, régression pénalisée | Probit : autre lien ; pénalisation : utile en présence de séparation ou de forte instabilité | Aucun besoin démontré pour l'instant ; reconsidérer si les diagnostics bloquent le logit |
| Arbres, forêts, boosting | Peuvent représenter des interactions, mais nécessitent réglage et validation adaptés | Pas d'objectif prédictif opérationnel ni de non-linéarité continue justifiant cette complexité à ce stade |
| Régression linéaire gaussienne, Poisson, survie | Cibles et hypothèses différentes | Non retenues pour cette décision annuelle binaire ; une étude du temps jusqu'au diplôme serait un autre travail |

Un GLMM sur le panel demanderait aussi de traiter la rétention dépendant du
résultat précédent. Le niveau atteint et la présence dans le panel peuvent
devenir associés à l'effet individuel latent. Un intercept aléatoire ne rend
pas ces mécanismes ignorables et ne transforme pas le modèle en analyse causale.
La restriction initiale évite cette sélection produite *pendant* le panel,
sans supprimer la sélection antérieure des étudiants déjà en niveaux avancés.

## Spécification proposée avant toute estimation

Formule conceptuelle, non exécutée :

```text
logit P(validation = 1 | X, décision connue, dossier complet, année initiale)
  = intercept + niveau
    + indicatrice(FL_B) + indicatrice(FL_C) + indicatrice(FM_B)
    + type_bac + parcours_anterieur + boursier
```

Références : niveau L1 ; licence A pour les contrastes licence ; master A pour
le contraste master ; bac général ; entrée postbac ; bourse FALSE. Les autres
modalités du bac et du parcours restent des catégories distinctes, sans ordre
numérique artificiel. Toutes les variables sont catégorielles ; une hypothèse
de linéarité d'un âge ou d'un revenu continu n'a donc pas à être inventée.

La bourse est conservée comme caractéristique administrative exploratoire,
sans présumer d'une relation causale. Le simulateur n'introduit aucun effet
direct de bourse ou de formation dans l'équation de validation ; retrouver un
coefficient non nul ne démontrerait aucun effet réel. Les probabilités par
niveau, les relations avec le bac et la reprise d'études sont programmées.
L'effet individuel latent est volontairement non exporté : le GLM marginal
ne doit pas être évalué en exigeant qu'il retrouve exactement les coefficients
conditionnels de cette équation génératrice.

Variables exclues : moyenne et ECTS (construits à partir du résultat), diplôme,
transition suivante et situation ultérieure (postérieures à la cible), réponses
d'enquête (sélection et temporalité), identifiants (clés, pas caractéristiques),
cycle (redondant), prérequis (constants). Aucun âge, sexe ou indicateur social
absent des tables ne sera inventé. La bourse doit être disponible à la date
administrative de référence ; cette convention est propre aux données simulées.

## Données manquantes et biais

Le modèle principal porte sur les cas complets explicitement sélectionnés.
Le simulateur masque aléatoirement certaines informations ; cette connaissance
ne permet pas de supposer ce mécanisme dans une base réelle. Comparer les
effectifs et caractéristiques des inclus et des exclus, publier la couverture
et limiter l'interprétation à la population effectivement analysée.
Une éventuelle sensibilité sans bourse sera explicitement séparée du modèle
principal, pas utilisée pour sélectionner la formule selon les valeurs p.
Ni imputation de cible ni codage automatique d'un bac manquant en « autre ».

Les données ne contiennent ni mesure exhaustive des acquis antérieurs, ni
contexte pédagogique, ni facteur individuel latent. Les niveaux sont déjà
sélectionnés avant observation. Les odds ratios sont des rapports de cotes
conditionnels aux covariables du GLM, pas des rapports de probabilités ni des
effets causaux. Les intervalles illustreront l'incertitude du modèle sous ses
hypothèses ; ils ne décriront pas l'incertitude sur l'UPEC réelle.

## Plan de validation réservé à l'étape 20

1. Geler la sélection et les références ; décrire inclus/exclus. Partager les
   étudiants de la coupe initiale en apprentissage 80 % et test 20 %, stratifiés
   sur la cible, avec graine 20261020 et restauration de l'état aléatoire.
2. Vérifier les deux classes et toutes les modalités requises en apprentissage,
   le rang de la matrice et l'absence d'étudiant partagé. Aucun ajustement sur test.
3. Estimer le GLM binomial-logit sur apprentissage avec échec explicite en
   présence de NA imprévu ou de rang déficient. Examiner convergence,
   coefficients extrêmes, séparation possible, résidus, leviers et influence.
   En cas de blocage, revenir à une décision méthodologique documentée.
4. Publier coefficients, odds ratios et IC à 95 % (méthode explicitée), avec
   références et effectifs. Ne pas faire de sélection automatique pas à pas.
5. Sur le test : AUC avec orientation de la classe positive explicite, score
   de Brier, log-loss, calibration moyenne et par groupes de risque suffisamment
   grands. Comparer à une probabilité constante apprise sur l'apprentissage.
   Une éventuelle classification à 0,5 sera secondaire : aucun seuil métier
   n'est justifié pour une décision sur des étudiants.
6. Sauvegarder modèle, sélection des identifiants, références, diagnostics,
   performances et session dans des artefacts traçables. Le test ne sert pas
   à modifier la formule. Une estimation finale sur tous les cas complets,
   si produite séparément, ne recevra pas les performances du modèle initial
   comme si elle avait elle-même été évaluée indépendamment.

Cette validation est interne à 2023-2024, pas temporelle ni externe. Les années
suivantes ne deviendront pas un test indépendant en réutilisant les mêmes
étudiants. Une validation sur de nouveaux entrants L1 aurait un champ différent
et demanderait un protocole spécifique. L'étude longitudinale reste l'étape 22.

## Dépendances et références

`stats` est disponible dans l'environnement du projet. `lme4`, `geepack` et
`sandwich` ne le sont pas lors de l'audit. Aucune installation n'est nécessaire
pour le modèle principal proposé ; aucun package n'a été installé à l'étape 19.
`renv::status()` est cohérent. Les données préparées restent inchangées.

- [R — glm : estimation des modèles linéaires généralisés](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/glm.html).
- [lme4 — glmer : modèles mixtes généralisés](https://lme4.github.io/lme4/reference/glmer.html).
- [lme4 — isSingular : diagnostic de singularité](https://lme4.github.io/lme4/reference/isSingular.html).
- [Højsgaard, Halekoh et Yan — geepack et modèles marginaux pour données groupées](https://www.jstatsoft.org/article/view/v015i02).

Ces références documentent les méthodes et outils. Le choix de la coupe initiale,
des covariables et du plan de validation relève du présent protocole de projet.
La validation du choix a précédé la création de `R/modeling/model.R`
et `notebooks/06_modelisation.qmd`. L'implémentation conserve le modèle
d'apprentissage évalué, utilise des IC de Wald à 95 % et ne réestime pas
le modèle sur le test. La calibration par groupes utilise les bornes apprises
sur l'apprentissage. Les performances n'ont pas d'IC et restent celles d'une
validation interne unique, sans prétention de validation temporelle ou externe.
