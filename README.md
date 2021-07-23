Main project repository: [`briatte/epsaconf`](https://github.com/briatte/epsaconf)

# Data notes

- The main dataset containing all information is __`program.tsv`__. That fiel is also the only one that contains all fixes and improvements, and should therefore always be preferred to all other 'intermediary' ones, such as `authors.tsv` or `sessions.tsv`.

- Conference participants do not have a __unique author id__ in the raw data, and are identified by their full names instead. Even though there are __no homonyms__ (all author-affiliation pairs are unique), the code still creates an alphanumeric identifier that should be unique to the author and conference, by combining the name and affiliation of each participation to the `epsa2019` keyword, and by taking a 128-bit hash of that string.

- In a few cases, some participants have submitted __multiple affiliations__, sometimes pointing to the same entity under different names, sometimes not. The file `participants-fixes.tsv`, which was assembled by hand, solves all cases, either by providing a single affiliation per participant, or by combining two affiliations into a single one with `&&`. The latter affect 8 affiliations: [Adriana Buena](http://www.adrianabunea.com/), [Anita Gohdes](http://www.anitagohdes.net/), [Catherine de Vries](http://catherinedevries.eu/), [Christophe Crombez](https://tec.fsi.stanford.edu/people/christophe_crombez), [Dominik Hangartner](https://www.hangartner.net/), [Kathrin Ackermann](https://kathrinackermann.github.io/), [Raimondas Ibenskas](https://uk.linkedin.com/in/raimondas-ibenskas-b158a1170) and [Sebastian Ziaja](http://www.ziaja.koeln/).
