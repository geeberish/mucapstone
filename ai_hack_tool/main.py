# =========================================== WyrmAI ========================================== #
#
# Script Name:  main.py
# Description:  This script is on offline LLM powered hacking assistant that suggests linux
#               based on user queries and stored manual pages from all installed tools. It 
#               Leverages ChromaDB to store and retrieve relevant man pages sections and
#               utilizes an Ollama model to generate accurate command suggestions. The tool,
#               wyrmai, supports processing man pages, answering single queries, interactive chat
#               sessions and viewing session history.
# Author:       Matt Penn
# Created:      2025-04-17
# Modified:     2025-05-02
# Version:      dev-2025-05-02
# Usage:        wyrmai --help
# Dependencies: chromadb, sentence-transformers, ollama (all in requirements.txt file)
# Tested on:    Raspberry Pi 5, Ubuntu Server 25.04
# License:      Custom Academic License – for academic, non-commercial use only. See LICENSE.
# Notes:        Developed while attending Marymount University, CAE-CD, Arlington, VA, for the
#               class IT 489 Capstone Project. Project title: Offline AI Reconnaissance and
#               Hacking Tool. Team Members: Richard Flores, Natasha Menon, and Charles "Matt" Penn.
#
# =============================================================================================== #



import os
import argparse
import logging

# Setup logging (save log in user's home directory)
log_path = os.path.expanduser("~/wyrmai.log")
logging.basicConfig(filename=log_path, level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


def log_message(message):
    logging.info(message)

# Session history file
SESSION_FILE = "session_history.txt"

def save_session(query, response):
    with open(SESSION_FILE, "a") as f:
        f.write(f"You: {query}\nAI: {response}\n\n")

def chunk_text(text, chunk_size=100):
    words = text.split()
    return [" ".join(words[i:i + chunk_size]) for i in range(0, len(words), chunk_size)]

def get_chroma_collection():
    import chromadb
    chroma_client = chromadb.PersistentClient(path="./chroma_db")
    return chroma_client.get_or_create_collection(name="man_pages")

def get_sentence_model():
    from sentence_transformers import SentenceTransformer
    return SentenceTransformer("all-MiniLM-L6-v2")

def process_man_pages(directory="manpages"):
    """Extracts and stores man pages in ChromaDB."""
    collection = get_chroma_collection()
    model = get_sentence_model()

    directory = os.path.abspath(directory)  # Make sure it's an absolute path
    if not os.path.exists(directory):
        log_message(f"[ERROR] Directory '{directory}' does not exist.")
        print(f"Error: Directory '{directory}' does not exist.")
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
    print("[+] Man pages successfully processed and stored.")

def retrieve_man_page(query, top_k=3):
    """Retrieves relevant sections from stored man pages."""
    collection = get_chroma_collection()
    model = get_sentence_model()

    query_embedding = model.encode([query]).tolist()
    results = collection.query(query_embeddings=query_embedding, n_results=top_k)
    context_docs = results["documents"]

    # Flatten the list if it contains nested lists
    if context_docs:
        flat_context_docs = [item for sublist in context_docs for item in (sublist if isinstance(sublist, list) else [sublist])]
        return "\n".join(flat_context_docs)  # Join the top_k results as context
    else:
        log_message(f"[WARNING] No relevant documents found for query: {query}")
        return "No relevant context found. Please try rephrasing your query."

def generate_command_suggestion(query):
    """Generates a command suggestion using Ollama and retrieved man pages."""
    import ollama  # Also defer this until needed
    context_docs = retrieve_man_page(query)
    context = context_docs

    prompt = f"""
    You are an AI hacking assistant with access to Linux manual pages.
    Use the relevant information below to generate command suggestions. If the context below
    is not logical or relevant then use what you know to suggest the correct command.

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
