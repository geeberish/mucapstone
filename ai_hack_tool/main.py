import os
import argparse
import chromadb
import logging
from sentence_transformers import SentenceTransformer
import ollama

# Setup logging
logging.basicConfig(filename="ai_hack.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

def log_message(message):
    logging.info(message)

# Initialize ChromaDB and SentenceTransformer
chroma_client = chromadb.PersistentClient(path="./chroma_db")
collection = chroma_client.get_or_create_collection(name="man_pages")
model = SentenceTransformer("all-MiniLM-L6-v2")

# Session history file
SESSION_FILE = "session_history.txt"

def save_session(query, response):
    with open(SESSION_FILE, "a") as f:
        f.write(f"You: {query}\nAI: {response}\n\n")

def chunk_text(text, chunk_size=100):
    words = text.split()
    return [" ".join(words[i:i+chunk_size]) for i in range(0, len(words), chunk_size)]

def process_man_pages(directory="manpages"):
    """Extracts and stores man pages in ChromaDB."""
    for file in os.listdir(directory):
        with open(os.path.join(directory, file), "r") as f:
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
    print(results)
    context_docs = results["documents"]
    
    # Flatten the list if it contains nested lists
    if context_docs:
        # Flatten any nested lists into a single list of strings
        flat_context_docs = [item for sublist in context_docs for item in (sublist if isinstance(sublist, list) else [sublist])]
        return "\n".join(flat_context_docs)  # Join the top_k results as context
    else:
        log_message(f"[WARNING] No relevant documents found for query: {query}")
        return "No relevant context found. Please try rephrasing your query."


def generate_command_suggestion(query):
    """Generates a command suggestion using Ollama and retrieved man pages."""
    context_docs = retrieve_man_page(query)
    context = "\n".join(context_docs)
    
    prompt = f"""
    You are an AI hacking assistant with access to Linux manual pages.
    Use the relevant information below to generate command suggestions. If the context below
     is not logical or relevant then use what you knoow to suggest the correct command

    Context:
    {context}

    User Query: {query}
    Provide a valid command based on the retrieved manual information, context, and what you know.
    """
    
    response = ollama.chat(model="qwen2.5-coder:1.5b", messages=[{"role": "user", "content": prompt}])
    command_response = response['message']['content']
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