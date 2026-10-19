# Observatoire — Power BI

Ouvrir `Observatoire.pbip` avec Power BI Desktop, ou la tâche VS Code dédiée.
La procédure de construction, d'actualisation et la portée des tests sont
dans [le guide des tableaux de bord](../docs/tableaux_de_bord.md).

Les données sont fictives et ce démonstrateur est indépendant de l'UPEC.
Le modèle importe les tables produites par R dans `outputs/pipeline_dashboard/`.
Le paramètre local `DataFolder` doit être généré sur chaque poste.

Ne pas relancer le générateur après personnalisation des pages sans avoir
versionné ces modifications : il recrée les fichiers de définition.
