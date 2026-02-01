from openai import OpenAI

# Host IP
client = OpenAI(
    base_url="http://192.168.1.3:8000/v1",
    api_key="na"
)

# Test Completion
response = client.chat.completions.create(
    model="tiny-llama-chat",
    messages=[{"role": "user", "content": "Hello! Tell me a joke."}],
    max_tokens=50
)

print(response.choices[0].message.content)