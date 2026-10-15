-- Chaffe HQ: self-serve sign up with an invite code. Run once in SQL Editor.
-- Change the code below if you want a different one, and match it in hq.html (INVITE_CODE).

create or replace function public.handle_new_member()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if coalesce(new.raw_user_meta_data ->> 'invite', '') = 'CHAFFE-TEAM' then
    insert into public.hq_members (email) values (new.email) on conflict do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_member();
