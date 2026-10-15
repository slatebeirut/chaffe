-- Chaffe HQ: auto-confirm every new account so nobody has to click an email link.
-- Run once in Supabase > SQL Editor.

-- 1. Confirm everyone who already signed up and is still waiting.
update auth.users
set email_confirmed_at = now()
where email_confirmed_at is null;

-- 2. Confirm every future account at the moment it is created.
create or replace function public.auto_confirm_email()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.email_confirmed_at is null then
    new.email_confirmed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists auto_confirm_on_signup on auth.users;
create trigger auto_confirm_on_signup
  before insert on auth.users
  for each row execute function public.auto_confirm_email();
