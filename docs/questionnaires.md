# Questionnaires synthétiques — version 0.1

Paramètres et instruments acceptés à la demande de génération de la phase B,
le 18 octobre 2026 ; aucun recueil réel de réponses.

Projet personnel indépendant de l'UPEC. Aucune invitation réelle, coordonnée
personnelle ou connexion LimeSurvey n'est prévue. Les identifiants d'invitation
sont fictifs et séparés des réponses.

## Participation

Texte proposé : « Ce questionnaire appartient à un démonstrateur sur données
synthétiques. Vous pouvez laisser une question sans réponse. Aucun résultat
individuel ne sera diffusé. » Un futur questionnaire interactif comportera un
filtre de participation ; ne pas présenter les tables synthétiques comme des
consentements réels. Sans participation : invitation conservée, aucune réponse.

## Évaluation — juin de chaque année

Une invitation par inscription principale éligible et vague, ouverte du 1er au
30 juin de l'année de fin. Les trois questions sont facultatives.

| Code | Libellé | Champ d'export |
|---|---|---|
| EVAL_GLOBAL | Globalement, quel est votre niveau de satisfaction concernant votre formation cette année ? | satisfaction_globale |
| EVAL_CONTENUS | Quel est votre niveau de satisfaction concernant les contenus des enseignements ? | satisfaction_contenus |
| EVAL_ACCOMP | Quel est votre niveau de satisfaction concernant l'accompagnement pédagogique ? | satisfaction_accompagnement |

Modalités communes : 1 très insatisfait, 2 plutôt insatisfait, 3 ni satisfait ni
insatisfait, 4 plutôt satisfait, 5 très satisfait ; `NC` non concerné. La valeur
brute vide diffère de `NC`. Normalisation : `NC` devient `NA` avec motif
`non_concerne` ; une absence devient `NA` avec `non_reponse_item`. Les valeurs
1 à 5 restent des entiers. Les motifs suivent les noms du dictionnaire des données.

`complete` : trois items renseignés (1 à 5 ou NC) ; `partielle` : au moins un
renseigné mais pas les trois ; `aucune` : aucun. Une invitation sans réponse n'a
pas de ligne dans `evaluations`. Le taux de satisfaction n'utilise que les
modalités numériques de l'item global. Pas de commentaire libre ni score composite.

## Devenir — situation à six mois

Diplômés de référence éligibles selon le protocole, collecte du sixième au
septième mois après diplôme, bornes incluses. Les questions portent sur la date
de référence, pas sur une situation ayant éventuellement changé à la réponse.

| Code | Libellé | Modalités et filtre |
|---|---|---|
| DEV_SITUATION | Quelle était votre situation principale à la date de référence affichée, six mois après le diplôme ? Si vous étudiiez, y compris en alternance, choisissez études. | etudes, emploi_hors_etudes, recherche_emploi_hors_etudes, autre_hors_etudes, NSP |
| DEV_EMP_ETUDES | À cette même date, exerciez-vous aussi une activité professionnelle, y compris en alternance ? | oui/non, seulement si etudes |

La première question devient `situation_six_mois`. `NSP` devient `NA` avec motif
`ne_sait_pas` ; une absence devient `NA` avec `non_reponse_item`. La seconde
devient `emploi_pendant_etudes`, logique, avec motif `non_applicable` hors études
ou si situation inconnue, et `non_reponse_item` si applicable mais vide.

Une ligne est conservée si la personne participe au module, même si la situation
reste inconnue. `complete` exige situation connue et items applicables renseignés ;
sinon `partielle`. `aucune` n'a pas de ligne de réponse. I09 compte les situations
connues, pas toutes les réponses partielles. Une cohorte immature n'est pas invitée
et ne fait jamais partie des non-répondants.

## Préparation LimeSurvey

Conserver codes, modalités, dictionnaire de correspondance, identifiant fictif
d'invitation, vague et date de réponse. Le format technique exact sera vérifié
sur un export de démonstration avant import. Détecter les doublons plutôt que
retenir silencieusement la dernière réponse. Aucun service externe n'est connecté.

L'étape 21 précise le plan de collecte, les expressions de pertinence proposées,
les correspondances de codes et la recette dans
[le protocole d'enquête](protocole_enquete.md). Le notebook 07 exploite les tables
synthétiques existantes ; aucun export provenant d'une instance LimeSurvey n'a
été importé ou validé à ce stade.
