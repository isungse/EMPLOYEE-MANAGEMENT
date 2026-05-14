"use client";

import { useActionState } from "react";
import { useState } from "react";
import { KeyRound, LogIn, ShieldCheck } from "lucide-react";
import type { AuthFormState } from "@/app/login/actions";
import { changePasswordAction, loginAction } from "@/app/login/actions";

const initialState: AuthFormState = {
  status: "idle",
  message: ""
};

function StatusMessage({ state }: { state: AuthFormState }) {
  if (state.status === "idle") return null;

  const className =
    state.status === "success"
      ? "border-emerald-200 bg-emerald-50 text-emerald-800"
      : "border-red-200 bg-red-50 text-red-800";

  return <div className={`rounded-md border px-3 py-2 text-sm font-semibold ${className}`}>{state.message}</div>;
}

export function LoginWorkspace() {
  const [showPasswordChange, setShowPasswordChange] = useState(false);
  const [loginState, loginFormAction, isLoginPending] = useActionState(loginAction, initialState);
  const [changeState, changeFormAction, isChangePending] = useActionState(changePasswordAction, initialState);

  return (
    <div className="mx-auto grid max-w-[480px] gap-6">
      <section className="panel p-6">
        <div className="mb-6 flex items-center gap-3">
          <span className="inline-flex h-10 w-10 items-center justify-center rounded-md bg-orange-50 text-primary ring-1 ring-orange-200">
            <ShieldCheck size={20} />
          </span>
          <div>
            <h1 className="text-xl font-bold tracking-normal text-gray-900">LOG IN</h1>
          </div>
        </div>

        <form action={loginFormAction} className="grid gap-4">
          <label className="form-field">
            <span>아이디</span>
            <input name="email" type="email" autoComplete="username" placeholder="admin@ptsm.co.kr" />
          </label>

          <label className="form-field">
            <span>비밀번호</span>
            <input name="password" type="password" autoComplete="current-password" />
          </label>

          <StatusMessage state={loginState} />

          <button
            type="submit"
            disabled={isLoginPending}
            className="mt-2 inline-flex h-11 items-center justify-center gap-2 rounded-md bg-primary px-4 text-sm font-bold text-white transition-colors hover:bg-orange-600 disabled:cursor-not-allowed disabled:opacity-60"
          >
            <LogIn size={17} />
            {isLoginPending ? "확인 중" : "로그인"}
          </button>
        </form>

        <div className="mt-4 flex justify-end">
          <button
            type="button"
            className="text-sm font-semibold text-gray-500 transition-colors hover:text-gray-900"
            onClick={() => setShowPasswordChange((value) => !value)}
          >
            비밀번호 변경
          </button>
        </div>
      </section>

      {showPasswordChange ? (
        <section className="panel p-6">
          <div className="mb-6 flex items-center gap-3">
            <span className="inline-flex h-10 w-10 items-center justify-center rounded-md bg-slate-50 text-gray-700 ring-1 ring-border">
              <KeyRound size={20} />
            </span>
            <div>
              <h2 className="text-xl font-bold tracking-normal text-gray-900">비밀번호 변경</h2>
              <p className="mt-1 text-sm font-medium text-gray-500">Password Update</p>
            </div>
          </div>

          <form action={changeFormAction} className="grid gap-4">
            <label className="form-field">
              <span>아이디</span>
              <input name="change-email" type="email" autoComplete="username" placeholder="admin@ptsm.co.kr" />
            </label>

            <label className="form-field">
              <span>현재 비밀번호</span>
              <input name="current-password" type="password" autoComplete="current-password" />
            </label>

            <label className="form-field">
              <span>새 비밀번호</span>
              <input name="new-password" type="password" autoComplete="new-password" />
            </label>

            <label className="form-field">
              <span>새 비밀번호 확인</span>
              <input name="confirm-password" type="password" autoComplete="new-password" />
            </label>

            <StatusMessage state={changeState} />

            <button
              type="submit"
              disabled={isChangePending}
              className="mt-2 inline-flex h-11 items-center justify-center gap-2 rounded-md border border-border bg-white px-4 text-sm font-bold text-gray-800 transition-colors hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60"
            >
              <KeyRound size={17} />
              {isChangePending ? "변경 중" : "비밀번호 변경"}
            </button>
          </form>
        </section>
      ) : null}
    </div>
  );
}
