"""
Service d'envoi des emails EventLink via SMTP Brevo.
"""

import smtplib
from email.message import EmailMessage

from app.config.settings import settings


def construire_email_code(
    email: str,
    code: str,
) -> EmailMessage:
    """Construit l'email contenant le code de vérification."""

    message = EmailMessage()

    message["Subject"] = "🔐 Votre code de vérification EventLink"
    message["From"] = (
        f"{settings.EMAIL_FROM_NAME} <{settings.EMAIL_FROM}>"
    )
    message["To"] = email

    duree = settings.EMAIL_VERIFICATION_CODE_EXPIRE_MINUTES

    # ------------------------------------------------------------------
    # Version texte brut
    # ------------------------------------------------------------------
    message.set_content(
        f"""🟠 EVENTLINK

🔐 Réinitialisation de votre mot de passe

Bonjour 👋,

Vous avez demandé à réinitialiser le mot de passe de votre compte EventLink.

🔑 Votre code de vérification :

{code}

⏱️ Ce code est valable pendant {duree} minutes.

Entrez ce code dans l'application EventLink pour continuer.

🛡️ Votre sécurité avant tout

Si vous n'êtes pas à l'origine de cette demande, vous pouvez simplement ignorer cet email.
Votre mot de passe actuel reste inchangé.

🚫 Ne partagez jamais ce code avec quelqu'un d'autre.

────────────────────────────────

🟠 EventLink
Ne ratez plus jamais un évènement. 📅✨

© 2026 EventLink
"""
    )

    # ------------------------------------------------------------------
    # Version HTML
    # ------------------------------------------------------------------
    html = f"""\
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code de vérification EventLink</title>
</head>

<body style="
    margin: 0;
    padding: 0;
    background-color: #F7F7F7;
    font-family: Arial, Helvetica, sans-serif;
    color: #242424;
">

    <table
        role="presentation"
        width="100%"
        cellspacing="0"
        cellpadding="0"
        border="0"
        style="
            width: 100%;
            margin: 0;
            padding: 0;
            background-color: #F7F7F7;
        "
    >
        <tr>
            <td align="center" style="padding: 30px 15px;">

                <table
                    role="presentation"
                    width="100%"
                    cellspacing="0"
                    cellpadding="0"
                    border="0"
                    style="
                        max-width: 600px;
                        width: 100%;
                        background-color: #FFFFFF;
                        border-radius: 18px;
                        overflow: hidden;
                        box-shadow: 0 4px 18px rgba(0, 0, 0, 0.08);
                    "
                >

                    <!-- En-tête EventLink -->
                    <tr>
                        <td
                            align="center"
                            style="
                                background-color: #FF6B1A;
                                padding: 28px 20px;
                            "
                        >
                            <div style="
                                display: inline-block;
                                width: 52px;
                                height: 52px;
                                line-height: 52px;
                                background-color: #FFFFFF;
                                border-radius: 50%;
                                font-size: 26px;
                                margin-bottom: 10px;
                            ">
                                🟠
                            </div>

                            <div style="
                                color: #FFFFFF;
                                font-size: 27px;
                                font-weight: 700;
                                letter-spacing: 1px;
                            ">
                                EVENTLINK
                            </div>

                            <div style="
                                margin-top: 7px;
                                color: #FFF4ED;
                                font-size: 14px;
                            ">
                                Ne ratez plus jamais un évènement.
                            </div>
                        </td>
                    </tr>

                    <!-- Contenu principal -->
                    <tr>
                        <td style="padding: 35px 35px 25px 35px;">

                            <div style="
                                text-align: center;
                                font-size: 34px;
                                margin-bottom: 12px;
                            ">
                                🔐
                            </div>

                            <h1 style="
                                margin: 0 0 15px 0;
                                text-align: center;
                                color: #242424;
                                font-size: 24px;
                                line-height: 1.3;
                            ">
                                Réinitialisation du mot de passe
                            </h1>

                            <p style="
                                margin: 0 0 18px 0;
                                font-size: 16px;
                                line-height: 1.6;
                                color: #555555;
                            ">
                                Bonjour 👋,
                            </p>

                            <p style="
                                margin: 0 0 25px 0;
                                font-size: 16px;
                                line-height: 1.6;
                                color: #555555;
                            ">
                                Vous avez demandé à réinitialiser le mot de passe
                                de votre compte <strong style="color: #FF6B1A;">
                                EventLink</strong>.
                            </p>

                            <!-- Titre du code -->
                            <div style="
                                text-align: center;
                                margin-bottom: 10px;
                                color: #555555;
                                font-size: 15px;
                                font-weight: 600;
                            ">
                                🔑 Votre code de vérification
                            </div>

                            <!-- Code -->
                            <div style="
                                margin: 0 auto 20px auto;
                                padding: 22px 15px;
                                max-width: 420px;
                                background-color: #FFF3EC;
                                border: 2px solid #FF6B1A;
                                border-radius: 14px;
                                text-align: center;
                            ">
                                <span style="
                                    color: #FF6B1A;
                                    font-size: 34px;
                                    font-weight: 700;
                                    letter-spacing: 9px;
                                    font-family: Arial, Helvetica, sans-serif;
                                ">
                                    {code}
                                </span>
                            </div>

                            <!-- Expiration -->
                            <div style="
                                text-align: center;
                                margin-bottom: 28px;
                                color: #777777;
                                font-size: 14px;
                            ">
                                ⏱️ Ce code est valable pendant
                                <strong>{duree} minutes</strong>.
                            </div>

                            <p style="
                                margin: 0 0 28px 0;
                                font-size: 15px;
                                line-height: 1.6;
                                color: #555555;
                            ">
                                Entrez ce code dans l'application
                                <strong>EventLink</strong> pour continuer
                                la réinitialisation de votre mot de passe.
                            </p>

                            <!-- Bloc sécurité -->
                            <div style="
                                padding: 18px;
                                background-color: #F8F8F8;
                                border-left: 4px solid #FF6B1A;
                                border-radius: 8px;
                                margin-bottom: 10px;
                            ">
                                <div style="
                                    font-size: 16px;
                                    font-weight: 700;
                                    color: #333333;
                                    margin-bottom: 8px;
                                ">
                                    🛡️ Votre sécurité avant tout
                                </div>

                                <div style="
                                    font-size: 14px;
                                    line-height: 1.6;
                                    color: #666666;
                                ">
                                    Si vous n'êtes pas à l'origine de cette
                                    demande, vous pouvez simplement ignorer
                                    cet email. Votre mot de passe actuel reste
                                    inchangé.
                                </div>
                            </div>

                            <p style="
                                margin: 18px 0 0 0;
                                text-align: center;
                                font-size: 13px;
                                color: #888888;
                            ">
                                🚫 Ne partagez jamais ce code avec quelqu'un
                                d'autre.
                            </p>

                        </td>
                    </tr>

                    <!-- Séparateur -->
                    <tr>
                        <td style="padding: 0 35px;">
                            <div style="
                                height: 1px;
                                background-color: #EEEEEE;
                            "></div>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td
                            align="center"
                            style="
                                padding: 25px 20px 30px 20px;
                            "
                        >
                            <div style="
                                color: #FF6B1A;
                                font-size: 19px;
                                font-weight: 700;
                            ">
                                🟠 EventLink
                            </div>

                            <div style="
                                margin-top: 7px;
                                color: #777777;
                                font-size: 13px;
                            ">
                                Ne ratez plus jamais un évènement. 📅✨
                            </div>

                            <div style="
                                margin-top: 15px;
                                color: #AAAAAA;
                                font-size: 11px;
                            ">
                                © 2026 EventLink — Tous droits réservés.
                            </div>
                        </td>
                    </tr>

                </table>

            </td>
        </tr>
    </table>

</body>
</html>
"""

    message.add_alternative(html, subtype="html")

    return message


def envoyer_code_verification(
    email: str,
    code: str,
) -> None:
    """
    Envoie le code de vérification via SMTP Brevo.

    Cette fonction est synchrone volontairement pour rester simple
    dans le MVP. Elle est appelée depuis le service d'authentification.
    """

    if not settings.EMAIL_HOST:
        raise RuntimeError("EMAIL_HOST n'est pas configuré.")

    if not settings.EMAIL_USERNAME:
        raise RuntimeError("EMAIL_USERNAME n'est pas configuré.")

    if not settings.EMAIL_PASSWORD:
        raise RuntimeError("EMAIL_PASSWORD n'est pas configuré.")

    if not settings.EMAIL_FROM:
        raise RuntimeError("EMAIL_FROM n'est pas configuré.")

    message = construire_email_code(
        email,
        code,
    )

    with smtplib.SMTP(
        settings.EMAIL_HOST,
        settings.EMAIL_PORT,
        timeout=30,
    ) as smtp:
        smtp.starttls()
        smtp.login(
            settings.EMAIL_USERNAME,
            settings.EMAIL_PASSWORD,
        )
        smtp.send_message(message)
