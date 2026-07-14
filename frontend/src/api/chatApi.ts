import axiosClient from "./axiosClient";

export const chatApi = {
  getActiveSession: async () => {
    const res: any = await axiosClient.get("/chat/session/active");
    return res.data;
  },
  getSessions: async () => {
    const res: any = await axiosClient.get("/chat/sessions");
    return res.data;
  },
  getMessages: async (sessionId: string) => {
    const res: any = await axiosClient.get(`/chat/messages/${sessionId}`);
    return res.data;
  },
  sendMessage: async (sessionId: string, content: string) => {
    const res: any = await axiosClient.post(`/chat/messages/${sessionId}`, `"${content}"`, {
      headers: { "Content-Type": "application/json" }
    });
    return res.data;
  }
};
