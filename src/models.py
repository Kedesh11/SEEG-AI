"""
Modèles Pydantic pour la validation des données
"""
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import date


class QuestionsMTP(BaseModel):
    """Questions MTP (Métier, Talent, Paradigme)"""
    metier: List[str] = Field(default_factory=list)
    talent: List[str] = Field(default_factory=list)
    paradigme: List[str] = Field(default_factory=list)


class ReponsesMTP(BaseModel):
    """Réponses MTP (Métier, Talent, Paradigme)"""
    metier: List[str] = Field(default_factory=list)
    talent: List[str] = Field(default_factory=list)
    paradigme: List[str] = Field(default_factory=list)


class Offre(BaseModel):
    """Informations sur l'offre d'emploi"""
    intitule: Optional[str] = None
    reference: Optional[str] = None
    ligne_hierarchique: Optional[str] = None
    type_contrat: Optional[str] = None
    categorie: Optional[str] = None
    salaire_brut: Optional[str] = None
    statut: Optional[str] = None
    campagne_recrutement: Optional[str] = None
    active: bool = True
    date_embauche: Optional[str] = None
    lieu_travail: Optional[str] = None
    date_limite_candidature: Optional[str] = None
    missions_principales: Optional[str] = None
    connaissances_requises: Optional[str] = None
    questions_mtp: QuestionsMTP = Field(default_factory=QuestionsMTP)
    date_publication: Optional[str] = None
    autres_informations: Optional[str] = None


class Documents(BaseModel):
    """Documents extraits par OCR"""
    cv: Optional[str] = None
    cover_letter: Optional[str] = None
    diplome: Optional[str] = None
    certificats: Optional[str] = None


class Candidature(BaseModel):
    """Modèle complet d'une candidature"""
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    offre: Offre = Field(default_factory=Offre)
    reponses_mtp: ReponsesMTP = Field(default_factory=ReponsesMTP)
    documents: Documents = Field(default_factory=Documents)
    
    # Champs techniques pour la gestion
    candidat_id: Optional[str] = Field(default=None, alias="_id")
    
    class Config:
        populate_by_name = True
        json_schema_extra = {
            "example": {
                "first_name": "Sevan",
                "last_name": "Kedesh",
                "offre": {
                    "intitule": "Développeur Backend Senior",
                    "reference": "DEV-2025-001",
                    "type_contrat": "CDI",
                    "categorie": "Technique"
                },
                "documents": {
                    "cv": "Texte extrait du CV...",
                    "cover_letter": "Texte de la lettre..."
                }
            }
        }

