export interface FriendWithLocation {
    id: number;
    name: string;
    avatar: string | null;
    location: {
        latitude: string;
        longitude: string;
        timestamp: string;
    } | null;
}