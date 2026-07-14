import axiosClient from "./axiosClient";

export const articleApi = {
  getAll: async () => {
    const res: any = await axiosClient.get("/articles");
    return res.data;
  },
  getById: async (id: string) => {
    const res: any = await axiosClient.get(/articles/ + id);
    return res.data;
  },
  create: async (data: any) => {
    const res: any = await axiosClient.post("/articles", data);
    return res.data;
  },
  update: async (id: string, data: any) => {
    const res: any = await axiosClient.put(/articles/ + id, data);
    return res.data;
  },
  delete: async (id: string) => {
    const res: any = await axiosClient.delete(/articles/ + id);
    return res.data;
  }
};

