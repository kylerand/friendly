from typing import List

ReflectionPrompt = List[str]

PROMPTS: List[ReflectionPrompt] = [
    [
        "Pause for a moment.",
        "What small act can you take to show up for someone you care about?",
    ],
    [
        "Allow curiosity to guide you.",
        "How might you respect this person's current pace while staying connected?",
    ],
]

def get_reflection_prompts() -> List[ReflectionPrompt]:
    return PROMPTS.copy()
