from typing import Dict, List

from app.schemas.models import AmbientSignal, CheckIn, Friendship, Interaction, User


class InMemoryStorage:
    def __init__(self):
        self.users: Dict[str, User] = {}
        self.friendships: Dict[str, Friendship] = {}
        self.interactions: Dict[str, Interaction] = {}
        self.check_ins: Dict[str, CheckIn] = {}
        self.ambient_signals: Dict[str, AmbientSignal] = {}

    def save_user(self, user: User) -> None:
        self.users[user.id] = user

    def get_user(self, user_id: str) -> User | None:
        return self.users.get(user_id)

    def save_friendship(self, friendship: Friendship) -> None:
        self.friendships[friendship.id] = friendship

    def list_friendships(self, user_id: str) -> List[Friendship]:
        return [
            f
            for f in self.friendships.values()
            if f.user_id == user_id or f.friend_id == user_id
        ]

    def save_interaction(self, interaction: Interaction) -> None:
        self.interactions[interaction.id] = interaction

    def list_interactions(self, user_id: str) -> List[Interaction]:
        return [i for i in self.interactions.values() if i.user_id == user_id]

    def save_check_in(self, check_in: CheckIn) -> None:
        self.check_ins[check_in.id] = check_in

    def save_ambient_signal(self, signal: AmbientSignal) -> None:
        self.ambient_signals[signal.id] = signal

    def list_ambient_signals(self, user_id: str) -> List[AmbientSignal]:
        return [s for s in self.ambient_signals.values() if s.user_id == user_id]
