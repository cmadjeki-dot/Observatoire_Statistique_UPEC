# Dictionnaire des indicateurs — version 0.1

Date : 18 octobre 2026. Statut : référence de définition du cadrage. I03 et I04
font l'objet d'une application descriptive initiale dans le notebook 02. Le
notebook 05 applique I01 à I05 aux tables préparées ; le notebook 07 applique
I06/I07 et I09 à I11. Le notebook 10 applique le catalogue prioritaire, y compris
I08 à partir des décisions de diplôme, avec couverture et inconnus distincts.
Projet personnel indépendant de l'UPEC ; données exclusivement synthétiques.

Les fonctions réutilisables de l'étape 18 sont dans `R/analysis/descriptive.R`.
Les ventilations de validation portent sur l'année, le niveau, la formation,
le type de bac et la bourse, avec conservation des modalités manquantes. Chaque
taux possède son effectif et son dénominateur. Le taux principal reste absent
si le nombre de décisions connues est inférieur à dix ; couverture et borne
basse appliquent le même seuil à leur propre dénominateur. Les effectifs seuls
restent disponibles dans ces sorties techniques, qui demandent un examen du
masquage complémentaire avant diffusion. L'évolution des inscriptions compare
deux volumes annuels successifs sur l'effectif de l'année précédente ; la
première année et un effectif précédent inférieur à dix donnent `NA`.

## Conventions communes

Les populations et périodes suivent le protocole. Les filtres s'appliquent au
numérateur et au dénominateur. Les taux sont exprimés en pourcentage, avec leurs
effectifs. Dénominateur nul : `NA`, jamais zéro. Taux non affiché sous 10 unités.
Les exclusions et les manquants sont dénombrés séparément. Les inscriptions
annuelles éligibles sont actives au 31 octobre, dans le champ L/M proposé.

## I01 — Étudiants distincts

- **Finalité :** caractériser la population sans double comptage.
- **Population :** inscriptions annuelles éligibles dans les filtres.
- **Unité :** étudiant.
- **Numérateur :** nombre d'identifiants étudiants distincts.
- **Dénominateur :** sans objet, effectif.
- **Période :** une année, ou union explicite des trois années.
- **Exclusions :** inscriptions annulées et hors périmètre.
- **Manquants :** identifiant absent bloquant, sans imputation d'identité.
- **Limites :** ne pas sommer les effectifs annuels pour obtenir les distincts.

## I02 — Inscriptions principales

- **Finalité :** quantifier les inscriptions prises en charge.
- **Population :** inscriptions annuelles éligibles.
- **Unité :** inscription principale annuelle.
- **Numérateur :** nombre d'identifiants d'inscription distincts.
- **Dénominateur :** sans objet, effectif.
- **Période :** une année ou cumul explicitement nommé.
- **Exclusions :** inscriptions annulées et hors périmètre.
- **Manquants :** clé ou année absente bloquante.
- **Limites :** I01 et I02 coïncident annuellement dans le modèle à inscription
  principale unique, mais pas nécessairement sur l'ensemble de la période.

## I03 — Validation annuelle

- **Finalité :** décrire la réussite académique opérationnelle.
- **Population :** inscriptions éligibles avec décision annuelle connue.
- **Unité :** inscription principale annuelle.
- **Numérateur :** décisions de validation `oui`.
- **Dénominateur :** décisions `oui` + `non` de la même population.
- **Période :** année universitaire, après seconde session, au gel annuel.
- **Exclusions :** annulées, hors champ et décisions inconnues.
- **Manquants :** inconnus publiés avec I04, jamais convertis en échecs.
- **Limites :** pas un taux de diplôme ; comparer couverture et composition.
  Borne basse complémentaire : même numérateur sur toutes les inscriptions
  éligibles, explicitement étiquetée comme analyse de sensibilité.

## I04 — Résultats inconnus

- **Finalité :** mesurer la couverture de I03.
- **Population :** toutes les inscriptions annuelles éligibles.
- **Unité :** inscription principale annuelle.
- **Numérateur :** inscriptions dont la décision est inconnue au gel.
- **Dénominateur :** toutes les inscriptions annuelles éligibles.
- **Période :** même gel que I03.
- **Exclusions :** inscriptions annulées et hors champ.
- **Manquants :** une ligne résultat absente est une anomalie ; si le calcul
  reste autorisé après contrôle, elle compte comme résultat inconnu.
- **Limites :** un résultat inconnu ne signifie pas une non-validation.

## I05 — Transitions annuelles

Sous-indicateurs distincts : I05a passage, I05b redoublement, I05c réorientation,
I05d sortie observée, I05e poursuite intercycle, I05f autre transition.

- **Finalité :** décrire les parcours après l'inscription de départ.
- **Population :** inscriptions éligibles dont l'année suivante est dans le panel.
- **Unité :** inscription de départ et transition annuelle.
- **Numérateur :** effectif de l'état correspondant, classé selon le protocole ;
  un numérateur pour chacun des six sous-indicateurs.
- **Dénominateur :** toutes les inscriptions de départ de la population,
  y compris les sorties ; identique pour les six états.
- **Période :** 2023-2024 → 2024-2025 ou 2024-2025 → 2025-2026, séparément.
- **Exclusions :** départs 2025-2026 censurés, annulés et hors champ.
- **Manquants :** identifiants invalides bloquants ; décision inconnue empêchant
  passage/redoublement conduit à un état autre explicité.
- **Limites :** sortie du champ ne prouve pas un abandon. Les parts totalisent
  100 % avant arrondi ; aucun taux conditionnel aux seuls réinscrits sous ce nom.

## I06 — Réponse à l'évaluation

- **Finalité :** mesurer la participation à la vague.
- **Population :** invitations prévues pour tous les inscrits éligibles.
- **Unité :** invitation par inscription et vague.
- **Numérateur :** invitations avec au moins un item du module renseigné.
- **Dénominateur :** toutes les invitations de la vague.
- **Période :** vague annuelle de juin.
- **Exclusions :** hors champ de la vague ; doublons résolus avec traçabilité.
- **Manquants :** non-répondants conservés au dénominateur ; statut absent à la
  clôture signalé comme anomalie, pas converti en réponse négative.
- **Limites :** réponse partielle admise ; participation ne garantit pas
  représentativité. Afficher aussi le nombre de questionnaires complets.

## I07 — Satisfaction globale favorable

- **Finalité :** résumer l'item global avec sa distribution complète.
- **Population :** réponses valides à l'item global de la vague.
- **Unité :** réponse à l'item par inscription et vague.
- **Numérateur :** modalités 4 ou 5.
- **Dénominateur :** modalités 1 à 5 de cet item.
- **Période :** une vague annuelle d'évaluation.
- **Exclusions :** non-réponse à la vague, à l'item ou « non concerné ».
- **Manquants :** distinguer et publier ces trois exclusions et la couverture.
- **Limites :** concerne les répondants, pas tous les inscrits ; ne constitue
  ni un score psychométrique validé, ni une mesure objective de qualité.

## I08 — Attribution du diplôme en niveau terminal

- **Finalité :** distinguer attribution et validation annuelle.
- **Population :** inscriptions éligibles L3/M2 avec décision de diplôme connue.
- **Unité :** inscription principale terminale.
- **Numérateur :** inscriptions avec diplôme attribué.
- **Dénominateur :** décisions d'attribution `oui` + `non` en niveau terminal.
- **Période :** année de fin de cursus, gel annuel.
- **Exclusions :** autres niveaux, hors champ et décisions inconnues.
- **Manquants :** publier les décisions inconnues parmi tous les inscrits
  terminaux ; une absence de diplôme n'est pas à elle seule une décision non.
- **Limites :** ce n'est pas une diplomation à trois ans de cohorte d'entrants.

## I09 — Réponse au devenir

- **Finalité :** mesurer la couverture de l'observation à six mois.
- **Population :** diplômés retenus dont la collecte est close au gel.
- **Unité :** invitation par personne et diplôme de référence.
- **Numérateur :** invités avec situation à six mois connue.
- **Dénominateur :** toutes les invitations éligibles de la vague.
- **Période :** six mois après diplôme, collecte jusqu'au septième mois,
  gel au 30 septembre 2026.
- **Exclusions :** cohortes non encore observables et diplômes non retenus
  après sélection du plus récent éligible par personne dans la vague.
- **Manquants :** non-réponse et situation inconnue restent au dénominateur.
- **Limites :** réponse sur l'item situation ; un questionnaire ouvert ne suffit pas.

## I10 — Emploi parmi répondants hors études

- **Finalité :** décrire l'emploi hors poursuite d'études.
- **Population :** répondants I09 avec situation connue hors études.
- **Unité :** personne et diplôme de référence.
- **Numérateur :** emploi hors études.
- **Dénominateur :** emploi + recherche d'emploi + autre situation, hors études.
- **Période :** situation déclarée à six mois.
- **Exclusions :** études, non-répondants, situations inconnues, cohortes immatures.
- **Manquants :** aucune imputation d'emploi ; présenter I09 et les exclusions.
- **Limites :** ni taux de chômage, ni taux officiel d'insertion. L'alternance
  est classée en études pour la situation principale.

## I11 — Poursuite d'études parmi répondants

- **Finalité :** décrire les poursuites d'études après diplôme.
- **Population :** répondants I09 avec situation connue.
- **Unité :** personne et diplôme de référence.
- **Numérateur :** situation études, alternance comprise.
- **Dénominateur :** toutes les situations de référence connues.
- **Période :** situation déclarée à six mois.
- **Exclusions :** non-répondants, situations inconnues et cohortes immatures.
- **Manquants :** publier I09, sans assimiler non-réponse et absence d'études.
- **Limites :** activité professionnelle pendant les études décrite séparément ;
  I10 et I11 ne partagent pas le même dénominateur.

## L01 — Présence dans le champ à horizon égal (complément longitudinal)

- **Finalité :** suivre la présence des cohortes L1 à durée de suivi comparable.
- **Population :** étudiants dont la première inscription observée est en L1,
  cohorte définie par l'année de cette inscription, pas par une entrée certaine
  dans l'enseignement supérieur.
- **Unité :** étudiant, cohorte et horizon annuel.
- **Numérateur :** membres présents dans le champ à l'année de l'horizon.
- **Dénominateur :** tous les membres initiaux de cette même cohorte, même
  absents ensuite ; il reste constant au fil des horizons disponibles.
- **Période :** horizons 0/1/2 pour 2023-2024, 0/1 pour 2024-2025, 0 pour 2025-2026.
- **Exclusions :** premières observations hors L1, inscriptions hors champ,
  horizons postérieurs au panel. Aucune extrapolation ni remplissage à zéro.
- **Manquants :** clés ou transitions incohérentes bloquantes ; une absence
  d'inscription sur une année observable est une absence dans le champ, pas
  une valeur manquante du niveau d'un inscrit. Une réentrée reste observable.
- **Limites :** ne mesure ni l'abandon définitif ni la progression de niveau.
  Le dénominateur diffère des transitions I05, calculées sur les présents au
  départ. L'horizon 0 vaut 100 % par construction ; pas de taux sous dix unités.

Application : notebook 08 et `R/analysis/longitudinal.R`. Les matrices annuelles
de niveaux incluent les absences suivantes dans leur dénominateur de départ ;
les transitions de fin de panel restent censurées. Les sorties sont croisées
avec la décision de diplôme sans modifier la définition de I05d.

## Catalogue prioritaire — étape 24

`config/indicators.yml` sélectionne dix indicateurs : I02, I03, I05a, I05c,
I06, I07, I08, I09, I10 et I11. I01 et I04 restent des informations d'accompagnement
dans les annexes, les effectifs et les couvertures. I08 utilise les décisions
oui/non/inconnu des seuls niveaux terminaux L3/M2, sans substituer la décision
annuelle ou la présence d'une ligne dans la table des diplômes.

Chaque définition YAML documente finalité, population, unité, formule,
numérateur, dénominateur, période, exclusions, manquants, couverture et limites.
Les formules sont documentaires ; les calculs explicites sont dans
`R/analysis/indicators.R`. Modifier une définition demande de mettre en cohérence
code, catalogue et tests. Le seuil est au moins dix pour les taux et ne s'applique
pas aux effectifs. Aucune cible métier ni seuil d'alerte n'est inventé.

Le tableau technique contient 33 lignes : sept séries scolaires sur trois
années, dont deux transitions finales non observables, et trois séries de
devenir par année/type du diplôme pour quatre groupes éligibles. Le champ
scolaire est l'ensemble fictif L/M ; les ventilations par formation restent
dans les analyses précédentes. Le champ du devenir conserve la sélection du
dernier diplôme mature de chaque personne, les horizons et les types distincts.

Les champs `numerateur` et `denominateur` conservent les effectifs servant au
calcul, sans arrondir les valeurs stockées. `population_reference` est l'univers
amont avant exclusions propres au taux. `n_exclus` mesure l'écart entre cet
univers et son dénominateur ; les exclusions d'éligibilité du devenir avant
invitation sont décrites séparément. `n_manquants` peut être inclus au
dénominateur ou déjà exclu : on ne le somme pas automatiquement à `n_exclus`.
Les NC de satisfaction sont exclus mais ne sont pas des non-réponses.

`couverture_numerateur`, `couverture_denominateur` et `couverture_pct` décrivent
la couverture documentaire de la définition YAML. Pour I10, elle porte sur
toutes les situations connues parmi les invités, et non sur le dénominateur
restreint aux hors études de ce taux. Pour I02, la couverture est sans objet.
Les statuts sont `diffusable`, `effectif_insuffisant`, `denominateur_nul` ou
`non_observable`. Dans les trois derniers cas, la valeur est absente. Une
transition censurée a aussi un numérateur et un dénominateur absents.

`annee_universitaire` désigne le millésime scolaire ou l'année du diplôme,
`type_diplome` précise les groupes du devenir, `date_reference` la date
d'observation de l'indicateur et `date_gel` le gel global. Pas de devenir
2025-2026 pour une collecte non close, ni de transition au-delà du panel.
Les indicateurs sont propres au démonstrateur et ne constituent pas des
mesures officielles ou des effets causaux.
