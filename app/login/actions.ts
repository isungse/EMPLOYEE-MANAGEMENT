"use server";

import { redirect } from "next/navigation";
import { clearAdminSession, isAdminUser, setAdminSession } from "@/lib/auth/session";
import { getSupabaseAdmin } from "@/lib/supabase/server";

export type AuthFormState = {
  status: "idle" | "success" | "error";
  message: string;
};

const defaultErrorMessage = "입력한 계정 정보를 확인해 주세요.";

function readText(formData: FormData, name: string) {
  return String(formData.get(name) ?? "").trim();
}

function getAuthClient() {
  const client = getSupabaseAdmin();
  if (!client) throw new Error("DB 인증 환경변수가 설정되지 않았습니다.");
  return client;
}

export async function loginAction(_state: AuthFormState, formData: FormData): Promise<AuthFormState> {
  const email = readText(formData, "email").toLowerCase();
  const password = readText(formData, "password");

  if (!email || !password) {
    return { status: "error", message: "아이디와 비밀번호를 입력해 주세요." };
  }

  const client = getAuthClient();
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error || !isAdminUser(data.user)) {
    return { status: "error", message: defaultErrorMessage };
  }

  await setAdminSession(data.user);
  redirect("/");
}

export async function changePasswordAction(_state: AuthFormState, formData: FormData): Promise<AuthFormState> {
  const email = readText(formData, "change-email").toLowerCase();
  const currentPassword = readText(formData, "current-password");
  const newPassword = readText(formData, "new-password");
  const confirmPassword = readText(formData, "confirm-password");

  if (!email || !currentPassword || !newPassword || !confirmPassword) {
    return { status: "error", message: "모든 항목을 입력해 주세요." };
  }

  if (newPassword.length < 14) {
    return { status: "error", message: "새 비밀번호는 14자 이상이어야 합니다." };
  }

  if (newPassword !== confirmPassword) {
    return { status: "error", message: "새 비밀번호가 일치하지 않습니다." };
  }

  const client = getAuthClient();
  const { data, error } = await client.auth.signInWithPassword({ email, password: currentPassword });
  if (error || !isAdminUser(data.user)) {
    return { status: "error", message: defaultErrorMessage };
  }

  const { error: updateError } = await client.auth.updateUser({ password: newPassword });
  if (updateError) {
    return { status: "error", message: "비밀번호 변경에 실패했습니다." };
  }

  await clearAdminSession();
  return { status: "success", message: "비밀번호가 변경되었습니다. 새 비밀번호로 로그인해 주세요." };
}

export async function logoutAction() {
  await clearAdminSession();
  redirect("/login");
}
