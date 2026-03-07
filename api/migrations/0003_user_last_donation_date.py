from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0002_badge_charity_donation_impactupdate_needrequest_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='last_donation_date',
            field=models.DateField(blank=True, null=True),
        ),
    ]
