import "server-only";

import { createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import type { User } from "@supabase/supabase-js";

const ADMIN_ROLE = "hr_admin";
const COOKIE_NAME = "ptsm_admin_session";
const SESSION_MAX_AGE_SECONDS = 60 * 60 * 8;

export type AdminSession = {
  sub: string;
  email: string;
  role: typeof ADMIN_ROLE;
  exp: number;
};

function getSigningSecret() {
  const secret = process.env.ADMIN_SESSION_SECRET ?? process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!secret || secret.startsWith("replace-")) {
    throw new Error("관리자 세션 서명 키가 설정되지 않았습니다.");
  }
  return secret;
}

function base64UrlJson(value: AdminSession) {
  return Buffer.from(JSON.stringify(value), "utf8").toString("base64url");
}

function sign(payload: string) {
  return createHmac("sha256", getSigningSecret()).update(payload).digest("base64url");
}

function hasValidSignature(payload: string, signature: string) {
  const expected = Buffer.from(sign(payload));
  const actual = Buffer.from(signature);
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}

function getUserRole(user: User) {
  return typeof user.app_metadata?.role === "string" ? user.app_metadata.role : null;
}

export function isAdminUser(user: User | null | undefined) {
  if (!user?.email) return false;
  return getUserRole(user) === ADMIN_ROLE;
}

export async function setAdminSession(user: User) {
  if (!isAdminUser(user) || !user.email) {
    throw new Error("관리자 권한이 없는 계정입니다.");
  }

  const expiresAt = Math.floor(Date.now() / 1000) + SESSION_MAX_AGE_SECONDS;
  const payload = base64UrlJson({
    sub: user.id,
    email: user.email,
    role: ADMIN_ROLE,
    exp: expiresAt
  });
  const value = `${payload}.${sign(payload)}`;
  const cookieStore = await cookies();

  cookieStore.set(COOKIE_NAME, value, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: SESSION_MAX_AGE_SECONDS
  });
}

export async function clearAdminSession() {
  const cookieStore = await cookies();
  cookieStore.delete(COOKIE_NAME);
}

export async function getAdminSession(): Promise<AdminSession | null> {
  const cookieStore = await cookies();
  const cookieValue = cookieStore.get(COOKIE_NAME)?.value;
  if (!cookieValue) return null;

  const [payload, signature] = cookieValue.split(".");
  if (!payload || !signature || !hasValidSignature(payload, signature)) return null;

  try {
    const session = JSON.parse(Buffer.from(payload, "base64url").toString("utf8")) as AdminSession;
    if (session.role !== ADMIN_ROLE || session.exp <= Math.floor(Date.now() / 1000)) return null;
    return session;
  } catch {
    return null;
  }
}

export async function requireAdmin() {
  const session = await getAdminSession();
  if (!session) redirect("/login");
  return session;
}
