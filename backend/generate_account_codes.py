import asyncio
import secrets

from app.database.mongodb import (
    close_mongo_connection,
    connect_to_mongo,
    get_database,
)


def generer_code() -> str:
    caracteres = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

    return "EL-" + "".join(
        secrets.choice(caracteres)
        for _ in range(6)
    )


async def main() -> None:
    await connect_to_mongo()

    try:
        db = get_database()

        users = await db.users.find(
            {
                "$or": [
                    {"account_code": {"$exists": False}},
                    {"account_code": None},
                    {"account_code": ""},
                ]
            }
        ).to_list(length=None)

        print(f"{len(users)} compte(s) sans code.")

        for user in users:
            while True:
                code = generer_code()

                existe = await db.users.find_one(
                    {"account_code": code}
                )

                if existe is None:
                    break

            await db.users.update_one(
                {"_id": user["_id"]},
                {
                    "$set": {
                        "account_code": code,
                    }
                },
            )

            print(
                f"{user.get('prenom', '')} "
                f"{user.get('nom', '')} → {code}"
            )
    finally:
        await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(main())