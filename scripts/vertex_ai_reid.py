import vertexai
from vertexai.vision_models import MultiModalEmbeddingModel, Image
import base64

# --- CONFIGURACIÓN ---
PROJECT_ID = "sistem-tracker-t"
LOCATION = "us-central1"

def init_vertex():
    vertexai.init(project=PROJECT_ID, location=LOCATION)

def get_embedding(image_base64):
    """Generates a vector embedding for an image using Vertex AI."""
    model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding")
    
    # Decode base64 to bytes
    image_bytes = base64.b64decode(image_base64)
    image = Image(image_bytes)
    
    # Get embedding (1408 dimensions)
    embeddings = model.get_embeddings(image=image)
    return embeddings.image_embedding

def are_same_person(img1_b64, img2_b64, threshold=0.75):
    """
    Compares two images to determine if they show the same person.
    Uses Cosine Similarity between embeddings.
    """
    emb1 = get_embedding(img1_b64)
    emb2 = get_embedding(img2_b64)
    
    # Calculate Dot Product (Cosine Similarity for normalized vectors)
    dot_product = sum(a*b for a, b in zip(emb1, emb2))
    
    print(f"Similitud Visual: {dot_product:.4f}")
    
    if dot_product > threshold:
        return True # Es la misma persona
    else:
        return False # Son personas diferentes

# --- EJEMPLO DE USO (CLOUD FUNCTION) ---
# Esta función sería llamada desde el Dashboard o activada por Firestore
# cuando se detectan dos entradas con timestamps muy cercanos (Nivel 1).
