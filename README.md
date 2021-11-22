# PICO-frameExtraction
Katrien and Paul presented an initial idea of how a personal dynamic memory could be build up based on the combination of text analysis and information contained in knowledge graphs (see the Matilda microproject from the Venice meeting). The personal dynamic memory would contain here the referents of the entities evoked in a story, as well as the relations between them. The knowledge graphs are used as background information and can be used to resolve co-references or add additional relations that are not mentioned in the text to the personal dynamic memory. The representations captured in the PDM can then be used for a variety of tasks, including answering questions about the story, summarising the story, providing temporal, causal, etc. perspectives on the story, or explaining based on which prior information specific reasoning steps have been taken.  

In fact, the conceptual foundations and technical architecture that are required for the referent-based extraction of narratives and the automatic creation, extension and annotation of PICO graphs is to a large extent the same. We concluded that the PICO graphs are good to use in a first phase as the domain is more restricted and that gold annotations are abundantly available. In a second phase, we could work towards a new benchmark on the extraction of narratives from stories (T3.1 + T3.4).

This repository contains: 

- example systematic reviews from the biomedical domain
- the PICO ontology (semantic script) 
- the annotations of the systematic reviews with the PICO ontology (small narrative graph, in accordance with the semantic script)
