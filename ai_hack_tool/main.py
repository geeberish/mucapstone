import os
import argparse
import chromadb
import logging
from sentence_transformers import SentenceTransformer
import ollama

# Setup logging (save log in user's home directory)
log_path = os.path.expanduser("~/ai_hack.log")
logging.basicConfig(filename=log_path, level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def log_message(message):
    logging.info(message)

# Initialize ChromaDB and SentenceTransformer
try:
    chroma_client = chromadb.PersistentClient(path="./chroma_db")
    collection = chroma_client.get_or_create_collection(name="man_pages")
except Exception as e:
    print(f"[ERROR] Failed to initialize ChromaDB: {e}")
    exit(1)

try:
    model = SentenceTransformer("all-MiniLM-L6-v2")
except Exception as e:
    print(f"[ERROR] Failed to load SentenceTransformer model: {e}")
    exit(1)

# Session history file
SESSION_FILE = "session_history.txt"

def save_session(query, response):
    with open(SESSION_FILE, "a") as f:
        f.write(f"You: {query}\nAI: {response}\n\n")

def chunk_text(text, chunk_size=100):
    words = text.split()
    return [" ".join(words[i:i+chunk_size]) for i in range(0, len(words), chunk_size)]

def process_man_pages(directory=None):
    """Extracts and stores man pages in ChromaDB."""
    if directory is None:
        # Get directory where this script is installed
        script_dir = os.path.dirname(os.path.abspath(__file__))
        directory = os.path.join(script_dir, "manpages")

    if not os.path.exists(directory):
        print(f"[ERROR] Manpages directory not found: {directory}")
        return

    for file in os.listdir(directory):
        full_path = os.path.join(directory, file)
        if os.path.isdir(full_path):
            continue  # Skip directories like chroma_db
        with open(full_path, "r") as f:
            text = f.read()
        chunks = chunk_text(text)
        for i, chunk in enumerate(chunks):
            embedding = model.encode([chunk]).tolist()
            collection.add(ids=[f"{file}_{i}"], documents=[chunk], embeddings=embedding)
    log_message("[+] Man pages successfully processed and stored.")


def retrieve_man_page(query, top_k=3):
    """Retrieves relevant sections from stored man pages."""
    query_embedding = model.encode([query]).tolist()
    results = collection.query(query_embeddings=query_embedding, n_results=top_k)
    context_docs = results["documents"]

    # Flatten the list if it contains nested lists
    if context_docs:
        flat_context_docs = [item for sublist in context_docs for item in (sublist if isinstance(sublist, list) else [sublist])]
        return "\n".join(flat_context_docs)
    else:
        log_message(f"[WARNING] No relevant documents found for query: {query}")
        return "No relevant context found. Please try rephrasing your query."

def generate_command_suggestion(query):
    """Generates a command suggestion using Ollama and retrieved man pages."""
    context_docs = retrieve_man_page(query)
    context = context_docs  # already a string now

    prompt = f"""
    You are an AI hacking assistant with access to Linux manual pages.
    Use the relevant information below to generate command suggestions. If the context below
    is not logical or relevant then use what you know to suggest the correct command.

    Context:
    {context}

    User Query: {query}
    Provide a valid command based on the retrieved manual information, context, and what you know.
    """
    try:
        response = ollama.chat(model="qwen2.5-coder:1.5b", messages=[{"role": "user", "content": prompt}])
        command_response = response['message']['content']
    except Exception as e:
        command_response = f"[ERROR] Failed to get response from Ollama: {e}"
        log_message(command_response)
        return command_response

    log_message(f"User Query: {query}\nAI Response: {command_response}")
    save_session(query, command_response)
    return command_response

def interactive_chat():
    """Starts an interactive chat session with history."""
    print("AI Hacking Assistant (type 'exit' to quit)")
    while True:
        user_input = input("\nYou: ")
        if user_input.lower() in ["exit", "quit"]:
            print("Exiting chat...")
            break
        response = generate_command_suggestion(user_input)
        print(f"\nAI: {response}")

def main():
    parser = argparse.ArgumentParser(description="Offline AI-Assisted Hacking Tool using Ollama and ChromaDB")
    parser.add_argument("-p", "--process", action="store_true", help="Process and store man pages")
    parser.add_argument("-q", "--query", type=str, help="Ask the AI for a command suggestion")
    parser.add_argument("-i", "--interactive", action="store_true", help="Start an interactive chat session")
    parser.add_argument("-s", "--session", action="store_true", help="View previous session history")

    args = parser.parse_args()

    if args.process:
        process_man_pages()
    elif args.query:
        response = generate_command_suggestion(args.query)
        print(response)
    elif args.interactive:
        interactive_chat()
    elif args.session:
        if os.path.exists(SESSION_FILE):
            with open(SESSION_FILE, "r") as f:
                print(f.read())
        else:
            print("No session history found.")
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
