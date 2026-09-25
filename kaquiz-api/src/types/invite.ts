export interface IncomingInviteItem {
    id: number;
    sender: {
        id: number;
        name: string;
        avatar: string | null;
    };
    created_at: string;
}

export interface OutgoingInviteItem {
    id: number;
    recipient: {
        id: number;
        name: string;
        avatar: string | null;
    };
    created_at: string;
}